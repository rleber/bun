#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class Roff
    attr_accessor :context_stack
    attr_accessor :line_length
    attr_accessor :indent
    attr_accessor :next_indent
    attr_accessor :line_buffer
    attr_accessor :buffer_stack
    attr_accessor :center
    attr_accessor :fill
    attr_accessor :justify
    attr_accessor :tabbed
    attr_accessor :line_spacing
    attr_accessor :page_length
    attr_accessor :page_header_margin
    attr_accessor :page_top_margin
    attr_accessor :page_header_margin
    attr_accessor :page_footer_margin
    attr_accessor :page_bottom_margin
    attr_accessor :page_headers
    attr_accessor :page_footers
    attr_accessor :pages_built
    attr_accessor :translation
    attr_accessor :control_character
    attr_accessor :hyphenation_character
    attr_accessor :hyphenation_mode
    attr_accessor :parameter_characters
    attr_accessor :parameter_escape
    attr_accessor :expand_parameters
    attr_accessor :expand_substitutions
    attr_accessor :insert_characters
    attr_accessor :insert_escape
    attr_accessor :quote_characters
    attr_accessor :quote_escape
    attr_accessor :definitions
    attr_accessor :summary
    attr_accessor :unimplemented_commands
    attr_accessor :processed_commands
    attr_accessor :command_count
    attr_accessor :merge_string
    attr_accessor :pending_actions
    attr_accessor :traps
    attr_accessor :traps
    attr_accessor :page_number
    attr_accessor :output_file_stack
    attr_accessor :files
    attr_reader   :hyphenator 
    attr_reader   :page_line_count
    attr_reader   :shell

    DEFAULT_LINE_LENGTH = 65
    DEFAULT_PAGE_LENGTH = 66
    DEFAULT_PAGE_HEADERS = [[],[]]
    DEFAULT_PAGE_FOOTERS = [[],[]]
    IGNORED_COMMANDS = %w{bf fs hc hy nc nd no po pw uc}
    PAGE_NUMBER_CHARACTER = '%'
    PAGE_NUMBER_ESCAPE = '%%'
    HYPHEN = '-'
    RANDOM_SEED = 171356521420781904450221983666692326660

    def initialize(options={})
      @shell = Shell.new
      @debug = options[:debug]
      @summary = options[:summary]
      @line_length = DEFAULT_LINE_LENGTH
      @indent = 0
      @next_indent = 0
      @line_buffer = []
      @buffer_stack = []
      self.fill = true
      self.justify = true
      self.center = false
      self.tabbed = false
      @line_spacing = 1
      @page_length = DEFAULT_PAGE_LENGTH
      @page_top_margin = 4
      @page_header_margin = 2
      @page_footer_margin = 1 
      @page_bottom_margin = 4
      @page_line_count = 0
      @pages_built = 0
      @page_headers = DEFAULT_PAGE_HEADERS.compact
      @page_footers = DEFAULT_PAGE_FOOTERS.compact
      @random = Random.new(seed=RANDOM_SEED) # Do this, so results are reproducible
      @translation = []
      @hyphenator = Hyphenator.create(:knuth)
      @control_character = '.'
      @hyphenation_character = ''
      @hyphenation_mode = 
      @parameter_characters = @parameter_escape = ''
      @expand_parameters = true
      @expand_substitutions = true
      @insert_characters = @insert_escape = ''
      @quote_characters = @quote_escape = ''
      @definitions = {}
      set_time
      @context_stack = [BaseContext.new(self)]
      @unimplemented_commands = []
      @processed_commands = []
      @command_count = 0
      @merge_string = ''
      @pending_actions = []
      @traps = []
      @page_number = 1
      @output_file_stack = []
      push_output_file '-'
      @files = []
    end

    def set_time
      now = Time.now
      define_value 'year', now.year
      define_value 'mon',  now.month
      define_value 'day',  now.day
      define_value 'hour', now.hour
      define_value 'min',  now.min
      define_value 'sec',  now.sec
    end

    def define(name, obj)
      @definitions[name] = obj
    end

    def defined?(name)
      @definitions[name]
    end
    alias_method :get_definition, :defined?

    def define_value(name, value, options={})
      v = Value.new(self)
      v.name = name
      v.value = value
      v.merge!(options)
      define name, v
    end

    def define_macro(name, lines=[])
      m = Macro.new(self)
      m.name = name
      m.lines = lines
      Roff.copy_state self, m
      define name, m
    end

    def macro_definition(name)
      defn = @definitions[name]
      defn && defn[:type]==:macro && defn # i.e. return the macro definitiion, if it exists
    end

    def value_of(name)
      defn = @definitions[name]
      return nil unless defn
      if defn[:type] == :macro
        defn[:lines].join("\n")
      else
        v = defn[:value]
        if defn[:format]
          v = merge(right_justify_text(v.to_s, defn[:format].size), defn[:format])
        end
        v
      end
    end

    # Set additional values for a definition. values should be a hash
    def set_definition_values(name, values)
      stop "!Can't set values #{values.inspect}. #{name} is not defined" unless defined?(name)
      @definitions[name].merge!(values)
    end

    def push(context)
      @context_stack << context
    end

    def pop
      @context_stack.pop 
    end

    def stack_depth
      @context_stack.size
    end

    def eof?
      stack_depth == 0 || self.at_bottom
    end

    def stacked?
      stack_depth > 0
    end

    def ensure_stacked
      raise StackUnderflow, "No input in stack" unless stacked?
    end

    def current_context
      ensure_stacked
      @context_stack.last
    end

    def context_for_file(path)
      err "!File #{path} does not exist" unless File.exists?(path)
      f = FileContext.new(self, path: path, lines: split_lines(::File.read(path)), macro: self.macro)
      Roff.copy_state self, f if stacked?
      f
    end

    def context_for_text(text)
      t = TextContext.new(self, lines: split_lines(text), macro: self.macro)
      Roff.copy_state self, t if stacked?
      t
    end

    def context_for_macro(macro, *arguments)
      MacroContext.new(self, macro: macro, name: macro.name, lines: macro.lines, arguments: arguments)
    end

    context_attr_accessor :line_number
    context_attr_accessor :next_line_number
    context_attr_accessor :overridden_line_number
    context_attr_accessor :line
    context_attr_accessor :expanded_lines
    context_attr_accessor :expanded_line
    context_attr_accessor :expanded_line_number
    context_attr_accessor :command
    context_attr_accessor :command_arguments
    context_attr_accessor :parameter_characters
    context_attr_accessor :parameter_escape
    context_attr_reader   :context_type
    context_attr_reader   :name
    context_attr_reader   :path
    context_attr_reader   :lines
    context_attr_reader   :macro
    context_attr_reader   :arguments
    context_attr_reader   :at_bottom

    def split_lines(text)
      lines = text.to_s.split("\n")
      lines = [''] if lines.size == 0
      lines
    end

    # TODO Should work with a stack of sources
    def process(to='-', options={})
      push_output_file to
      self.next_line_number = 1
      while (self.line = get_line)
        self.expanded_lines = expand(self.line)
        expanded_lines.each.with_index do |expanded_line, i|
          self.expanded_line_number = i+1
          self.expanded_line = expanded_line
          process_line(expanded_line)
        end
        self.expanded_lines = self.expanded_line = self.expanded_line_number = nil # This is in here in case it's useful for debugging
      end
      force_break
      end_page if @pages_built > 0
    # Cause exceptions to be accompanied by a stack trace
    rescue => e
      log "!Exception occurred: #{e}"
      show_stack_trace('    ')
      raise
    ensure
      show_summary if summary
      show_all if summary && @debug
    end

    def process_line(line)
      if parse_command(line)
        process_command
      else
        output_line(line)
      end
    end

    def get_line
      line = nil
      loop do
        line = get_line_from_current_context
        break if line
        pop
        nil
        break if eof?
      end
      self.line = line if line
      line
    end

    def invoke_pending_actions(line)
      (pending_actions.size-1).downto(0) do |i|
        action = pending_actions[i]
        action[:count] -= 1
        if action[:count] <= 0
          action[:action].call(line)
          pending_actions.delete_at(i)
        else
        end
      end
    end

    def push_pending_action(count, &blk)
      self.pending_actions << {count: count, action: blk}
    end

    def set_trap(line, type=:temporary, &blk)
      self.traps << {line: line, type: type, action: blk}
    end

    def invoke_traps(line)
      -1.downto(-self.traps.size) do |i|
        trap = self.traps[i]
        next unless trap[:line] == line
        trap[:action].call(line)
        self.traps.delete_at(i) if trap[:type]==:temporary
      end
    end

    def get_line_from_current_context
      self.next_line_number = 1 unless self.next_line_number
      self.line_number = next_line_number
      line = if line_number > lines.size
        nil
      else
        self.next_line_number = next_line_number + 1
        lines[line_number-1]
      end
      line
    end

    def parse_command(line)
      words = command_words(line)
      if !@literal && words.size>0 && words[0]=~/^#{Regexp.escape(@control_character)}\S+/
        self.command = words.shift[/^#{Regexp.escape(@control_character)}(.*)/,1]
        self.command_arguments = words 
        self.command
      else
        self.command = self.command_arguments = nil
      end
    end

    def command_words(line)
      if @quote_characters == ''
        line.split(/\s+/)
      else
        q = Regexp.escape(@quote_characters)
        words = line.scan(/(?:#{q}[^#{q}]*#{q}|\S+)+|\s+/).reject{|w| w=~/^\s+$/}
        words.map {|w| w=~/^#{q}([^#{q}]*)#{q}$/ ? $1 : w }
      end
    end

    def command_escape(string)
      string=~/\s/ ? string.inspect : string
    end

    def process_command
      write_trace "Execute", [@control_character+command,*(command_arguments.map{|a| command_escape(a)})].join(' ')
      self.command_count += 1
      self.overridden_line_number = nil
      meth = "#{command}_command"
      if self.respond_to?(meth)
        # send_arguments = command_arguments[0,self.method(meth).arity.abs]
        send_arguments = command_arguments
        begin
          self.processed_commands << command
          self.send(meth, *send_arguments)
        rescue ArgumentError => e
          if !@debug && e.to_s =~ /wrong number of arguments (\(\d+\s+for\s+\d+\))/
            detail = " #{$1}"
          else
            raise
          end
          syntax "Wrong number of arguments#{detail} (Arguments #{command_arguments.inspect})"
        end
      elsif m = macro_definition(command)
        m.invoke(*command_arguments)
      else
        unimplemented
      end
      self.next_line_number = self.overridden_line_number || self.next_line_number
    end

    def line_part_spec
      spec = self.line[/^\.\w+\s+(.*)$/,1].strip
      ((spec.size==0 ? [] : spec[1..-1].split(spec[0])) + ['', '', ''])[0,3] \
                .map{|p| expand(p)} \
                .flatten
    end

    def evaluate_condition(condition)
      syntax "!Bad .if condition" unless condition =~ /^(.*)(<|=|>|<=|>=|!=)(.*)$/
      op1 = $1.strip
      comparison = $2
      op2 = $3.strip
      op2 = convert_integer(op2, "Second comparison operand")
      # TODO Should this depend on the quoting character?
      if op1 =~ /^"(?:[^"]|"")*"$/ # op1 is a quoted string
        tweaked_op1 = op1.gsub(/(?<!^)""/,'\\"')
        op1 = begin
          eval(tweaked_op1).size
        rescue SyntaxError => e
          syntax "bad string operand #{op1}"
        end
      elsif op1 =~ /^[+-]?\d+$/
        op1 = op1.to_i
      else
        syntax "!Bad operand #{op1.inspect} in condition"
      end
      comparison = '==' if comparison=='='
      begin
        op1.send(comparison, op2)
      rescue => e
        raise e.class, "(evaluating condition: #{condition}) #{e.to_s}", e.backtrace
      end
    end

    def _process_conditional(flag, &blk)
      if yield
        found = look_for_el_or_en(nil, flag) {|line| process_line(line) }
        look_for_en("Skip to #{flag}", flag) if found=='el'
      else
        found = look_for_el_or_en("Skip to #{flag}", flag)
        look_for_en(nil, flag) {|line| process_line(line) } if found=='el'
      end
    end

    def write_trace(flag="Execute", expanded_command)
      position, original_command = stack_trace.first.split(/\s*:\s*/)
      out = if expanded_command == original_command
        expanded_command
      else
        "#{expanded_command} <= #{original_command}"
      end
      info "*#{'%-25s'%flag} #{'%-60s' % out} @ #{position}"
    end

    def unimplemented
      unimplemented_commands << command
    end

    def log(msg)
      puts msg 
    end

    def info(msg)
      log msg if @debug
    end

    def syntax(msg='')
      err "!Syntax error: #{msg} in #{line}"
    end

    def err(msg)
      log msg
      show_stack_trace '    '
      raise RuntimeError, "Error raised" if @debug
      stop
    end

    def show_stack_trace(prefix='')
      stack_trace.each do |context|
        log "#{prefix}#{context}"
      end
    end

    # TODO Stack trace in macros should refer back to the line number in the original file
    def stack_trace
      trace = @context_stack.reverse.map do |context|
        next if context.context_type == :base
        ['Line', context.line_number.to_s, 'in', context.context_type.to_s, context.path, context.name, ':', context.line].compact.join(' ')
      end.compact
      if stacked? && expanded_lines && expanded_lines.size > 1
        trace.unshift ['Line', expanded_line_number, 'in', 'command expansion', ':', expanded_line].join(' ')
      end
      trace
    end

    def convert_relative_integer(base_value, arg, name)
      v = convert_integer(arg, name)
      case arg
      when /^[+-]/
        base_value + v
      else
        v
      end
    end

    def convert_integer(arg, name)
      err "!#{name} must be an integer" unless arg.to_s=~/^[+-]?\d+$/
      arg.to_i
    end

    def convert_positive_integer(arg, name)
      i = convert_integer(arg, name)
      err "!#{name} can't be negative" if i<0
      i 
    end

    def decode_tab_stops(*tabs)
      tabs = remove_relative_stops(*tabs)
      tabs.unshift(0) unless tabs[0].is_a?(Numeric)
      tabs.push(line_length) unless tabs[-1].is_a?(Numeric)
      left_stops, center_left_stops,  _           = look_for_previous_stops(*tabs)
      _,          center_right_stops, right_stops = look_for_previous_stops(*tabs.reverse)
      center_stops = merge_center_stops(center_left_stops, center_right_stops)
      stops = merge_all_stops(left_stops, center_stops, right_stops)
      stops.unshift [:indent, tabs[0]]
    end

    def remove_relative_stops(*tabs)
      last_tab_stop = 0
      # Replace '+nn' and 'nn' forms
      # TODO Seems like there might be a way to DRY out these two repeated loops
      tabs = tabs.map do |t|
        t.downcase!
        case t
        when 'l', 'c', 'r'
          t.to_sym
        when /^\+\d+$/
          last_tab_stop += t.to_i
        when /^-\d$/
          t # Leave these alone for now
        when /^\d+$/
          last_tab_stop = t.to_i
        else
          err "!Bad tab stop #{t}"
        end
      end
      # Replace "-nn" forms
      next_tab_stop = self.line_length
      tabs.reverse.map do |t|
        case t
        when Integer
          next_tab_stop = t
        when /^-\d$/
          next_tab_stop += t.to_i
        else
          t
        end
      end.reverse
    end

    def look_for_previous_stops(*tabs)
      last_stop = nil
      stops = {}
      tabs.each do |t|
        if t.is_a?(Numeric)
          last_stop = t
        else
          stops[t] ||= []
          stops[t] << last_stop
        end
      end
      [stops[:l]||[], stops[:c]||[], stops[:r]||[]]
    end

    def merge_center_stops(left, right)
      raise RuntimeError, "Should be an equal number of center-left and center-right stops" \
        unless left.size == right.size
      left.sort.zip(right.sort).map{|l,r| (l+r)/2.0}
    end

    def merge_all_stops(left, center, right)
      (
        left.map{|t| [:left, t] } +
        center.map {|t| [:center, t] } +
        right.map {|t| [:right, t] }
      ).sort_by {|pair| pair[1]}
    end

    # Encapsulates a common pattern: look for an .en with a matching flag
    def look_for_en(description, flag, options={}, &blk)
      look_for_command('en', description, flag, options, &blk)
    end

    # Encapsulates a common pattern: look for an .el with a matching flag
    def look_for_el(description, flag, options={}, &blk)
      look_for_command('el', description, flag, options, &blk)
    end

    # Encapsulates a common pattern: look for an .el or .en with a matching flag
    def look_for_el_or_en(description, flag, options={}, &blk)
      look_for_command(/^el|en$/, description, flag, options, &blk)
    end
    alias_method :look_for_en_or_el, :look_for_el_or_en

    def look_for_command(pattern, description, flag, options={}, &blk)
      flag = $1 if flag=~/^\((.*)\)$/
      expand_substitutions = options[:expand_substitutions]==true || (options[:expand_substitutions].nil? && self.expand_substitutions)
      while l = get_line do
        write_trace description, l if description
        if options[:no_expand]
          lines = [l]
        else
          lines = expand(l, expand_substitutions: expand_substitutions)
        end
        # TODO What happens if we match on the first part of a multi-line?
        lines.each do |l2|
          if parse_command(l2)
            case command
            when pattern # Do it this way, so pattern can be a string or regular expression
              case command_arguments.size
              when 0
                syntax "Missing tag in .#{command}"
              when 1
                command_flag = command_arguments.first
                # Is this right?
                command_flag = expand($1, expand_parameters: true, expand_substitutions: expand_substitutions)[0] if command_flag =~ /^\((.*)\)$/ 
                if command_flag == flag
                  self.command_count += 1
                  return command
                end
                yield(l2) if block_given?
              else
                syntax "Extra arguments in .#{command}"
              end
            else
              yield(l2) if block_given?
            end
          else 
            yield(l2) if block_given?
          end
        end
      end
      stop "!Missing #{description} #{flag}"
    end

    def get_escape(characters)
      case characters.size
      when 0
        ['', '']
      when 1
        [characters, '']
      when 2
        [characters[-1], characters]
      else
        err "!Special character sequence should be 0-2 characters"
      end
    end

    def output_line(line)
      if self.fill
        pieces = break_line(line)
        return if pieces.size == 0
        force_break if pieces.first =~ /^\s/
        pieces.each do |piece|
          put_piece(piece)
        end
        @line_buffer << (pieces.last =~ /[\.!?:]$/ ? '  ' : ' ') # Extra space after line ends
      else
        force_break if @line_buffer.size > 0
        self.line_buffer = [line] # Do it this way to force centering, translation, etc.
        flush
      end
      invoke_pending_actions(line)
    end

    def break_line(text)
      text.rstrip.scan(/\w+|\s+|./).map {|piece| piece=~/^\s+$/ ? ' ' : piece }
    end

    def put_piece(piece)
      return if @line_buffer.size==0 && piece=~/^\s+$/ # Don't start lines with spaces
      next_buffer = @line_buffer + [piece]
      next_buffer_size = next_buffer.join.size
      if next_buffer_size > net_line_length # Line overflow
        if self.hyphenation_mode==0 || piece =~ /[^a-zA-Z]/
          next_buffer = [piece]
        else # Attempt to hyphenate
          minimum_suffix_size = next_buffer_size - net_line_length + HYPHEN.size
          hyphenation_suffix = self.hyphenator.sentence_suffix(next_buffer, minimum_suffix_size)
          if hyphenation_suffix == '' || hyphenation_suffix == piece
            next_buffer = [piece]
          else
            @line_buffer << (piece[0...-(hyphenation_suffix.size)]+HYPHEN)
            next_buffer = [hyphenation_suffix]
          end
        end
        flush
      end
      @line_buffer = next_buffer
    end

    def net_line_length
      line_length - total_indent
    end

    def net_page_lines_left
      net_page_length - @page_line_count
    end

    def net_page_lines_left_at_spacing
      lines, remainder = net_page_lines_left.divmod(@line_spacing)
      lines += 1 if remainder > 0 && @page_line_count == 0 # Because we don't put blank lines at the top of a page
      lines
    end

    def total_indent
      [next_indent, 0].max 
    end

    def force_break
      flush(justify: false)
    end

    def flush(options={})
      justify = options[:justify]!=false && (options[:justify] || self.justify)
      unless @line_buffer.size == 0
        show_state if @debug
        if justify
          line = justify_line(@line_buffer)
        elsif self.fill
          trim_buffer @line_buffer
          line = @line_buffer.join
        elsif self.center
          trim_buffer @line_buffer
          line = center_buffer(@line_buffer)
        elsif self.tabbed
          line = tabbed_buffer(@line_buffer)
        else
          line = @line_buffer.join
        end
        @line_buffer = []
        put_line_paginated indent_text(transform(line), total_indent)
      end
      self.next_indent = self.indent
    end

    def transform(text)
      translate(merge(text, merge_string))
    end

    def merge(*strings)
      res = ''
      strings.each do |string|
        string ||= ''
        new_res = ''
        [res.size, string.size].max.times do |i|
          res_char = res[i]||' '
          string_char = string[i]||' '
          new_res += res_char==' ' ? string_char : res_char
        end
        res = new_res
      end
      res
    end

    def translate(text)
      @translation.size==0 ? text : text.tr(*@translation)
    end

    def center_buffer(buffer, at=nil)
      trim_buffer buffer
      center_text(buffer.join, at)
    end

    def center_text(text, at=nil)
      at ||= net_line_length/2.0
      return '' if text.size == 0
      indent_text text, (at - text.size/2.0).to_i
    end

    def right_justify_text(text, at=nil)
      at ||= net_line_length
      indent_text text, at - text.size
    end

    def indent_text(text, indent=0)
      padding(indent) + text
    end

    def left_justify_text(text, column=1)
      indent_text(text, column-1)
    end

    def padding(pad)
      (' '*[pad,0].max)
    end

    def justify_line(buffer)
      trim_buffer buffer
      return '' if buffer.size == 0
      padding = net_line_length - buffer.join.size
      spaces = buffer.select{|c| c=~/^\s+$/}.size
      return buffer.join if spaces==0
      pad1, remainder = padding.divmod(spaces)
      extra_locations = []
      extra_space_count = 0
      while extra_space_count < remainder
        loc = @random.rand(0...spaces)
        unless extra_locations.include?(loc)
          extra_locations << loc
          extra_space_count += 1
        end
      end
      space_counter = 0
      padded_buffer = buffer.map do |c| 
        if c=~/^\s+$/
          c += padding(pad1)
          c += ' ' if extra_locations.include?(space_counter)
          space_counter += 1
          c
        else
          c
        end
      end
      padded_buffer.join
    end

    def tabbed_buffer(buffer)
      tabbed_text(buffer.join(' '))
    end

    def tabbed_text(line)
      line_parts = line.split(/\t/)
      @tab_stops == [[:indent, @indent]] if @tab_stops.nil? || @tab_stops.size==0
      tabbed_parts = line_parts.zip(@tab_stops).map do |part, stop|
        if stop.nil?
          ' ' + part
        else
          case stop[0]
          when :center
            center_text part, stop[1]+1
          when :right
            right_justify_text part, stop[1]+1
          else
            left_justify_text part, stop[1]+1
          end
        end
      end
      merge(*tabbed_parts)
    end

    def trim_buffer(buffer)
      while buffer.size>0 && buffer.first =~ /^\s*$/
        buffer.delete_at(0)
      end
      while buffer.size>0 && buffer.last =~ /^\s*$/
        buffer.delete_at(-1)
      end
    end

    def get_file(fn)
      file = @files[convert_integer(fn, "File number")]
      err "!File number #{fn} is not defined" unless file
      file[:path]
    end

    def get_file_name(name)
      if name=~/^\*(.*)$/
        f_label = $1
        f = @files.find {|f_defn| f_defn && f_defn[:name]==f_label}
        return f[:path] if f
        f = Tempfile.new("roff_#{f_label}_")
        f.close 
        f.path
      else
        name
      end
    end

    def push_output_file(f)
      @output_file_stack << f
    end

    def pop_output_file
      @output_file_stack.pop
    end

    def current_output_file
      @output_file_stack[-1] || '-'
    end

    def put_line_paginated(line)
      unless @page_line_count == 0 # Don't put extra spaces at the top of a page
        (@line_spacing - 1).times { put_line_paginated_single_spaced '' }
      end
      put_line_paginated_single_spaced(line)
    end

    def net_page_length
      @page_length - @page_top_margin - @page_header_margin - @page_footer_margin - @page_bottom_margin
    end

    def put_line_paginated_single_spaced(line)
      start_page if @page_line_count == 0
      put_line line
      self.page_line_count = @page_line_count + 1
      finish_page if @page_line_count >= net_page_length
    end

    def page_line_count=(n)
      @page_line_count = n
      invoke_traps(n)
    end    

    def start_page
      break_page if @pages_built > 0
      put_headers
      @pages_built += 1
    end

    def finish_page
      end_page if @page_line_count>0
    end

    def end_page
      put_footers
      self.page_line_count = 0
    end

    def break_page
      put_line '-'*@line_length
      @page_number += 1
    end

    def put_headers
      header_set = @page_number % 2
      page_top_margin.times { put_line '' }
      @page_headers[header_set].each {|header| put_line_parts header }
      (page_header_margin - @page_headers[header_set].size).times { put_line '' }
    end

    def put_footers
      footer_set = @page_number % 2
      (page_footer_margin - @page_footers[footer_set].size).times { put_line '' }
      @page_footers[footer_set].each {|footer| put_line_parts footer }
      page_bottom_margin.times { put_line '' }
    end

    def put_line_parts(parts)
      parts = parts.map {|p| p.gsub('%', @page_number.to_s )}
      put_line build_line_from_parts(parts)
    end

    def build_line_from_parts(parts)
      merge(parts[0]||'', center_text(parts[1]||'', line_length/2.0),right_justify_text(parts[2]||'', line_length))
    end

    def page_lines_left
      @page_length - @page_line_count
    end

    def put_line(line)
      shell.puts(current_output_file, line)
    end

    def show_summary(indent=0)
      unimplemented_commands = self.unimplemented_commands.uniq
      processed_commands = self.processed_commands.uniq
      noteworthy_unimplemented_commands = unimplemented_commands - IGNORED_COMMANDS
      ignored_commands_implemented = IGNORED_COMMANDS & processed_commands
      ignored_commands_not_encountered = IGNORED_COMMANDS - unimplemented_commands - ignored_commands_implemented
      ignored_commands_encountered = IGNORED_COMMANDS - ignored_commands_not_encountered - ignored_commands_implemented

      warn ''
      warn_with_indent "Roff Execution Summary:", indent
      warn_with_indent "#{command_count} commands executed", indent+4
      warn_with_indent "Unimplemented commands:       " + printable_list(noteworthy_unimplemented_commands.sort),
        indent+4 \
        if noteworthy_unimplemented_commands.size > 0
      warn_with_indent "Ignored commands encountered: " + printable_list(ignored_commands_encountered.uniq.sort),
        indent+4  \
        if ignored_commands_encountered.size > 0
      warn_with_indent "Ignored commands implemented: " + printable_list(ignored_commands_implemented.uniq.sort),
        indent+4  \
        if ignored_commands_implemented.size > 0
      warn_with_indent "Other ignored commands:       " + printable_list(ignored_commands_not_encountered.uniq.sort),
        indent+4  \
        if ignored_commands_not_encountered.size > 0
    end

    def printable_list(ary)
      ary.map {|ary| ary.to_s}.join(' ')
    end

    def show_item(type, name=nil, indent=0)
      case type.downcase  
      when 'all'
        show_all
      when 'file'
        err "Must include name" unless name
        if name=~/^\d+$/
          i = name.to_i
          err "File ##{i} is not defined" if i<1 || i>=@files.size
          show_file_from_defn(@files[i])
        elsif (f=@files.find {|file| file && file[:name]==name.sub(/^\*/,'')})
          show_file_from_defn(f, indent)
        else
          syntax "Bad file specifier: #{name}"
        end
      when 'macro'
        err "Must include name" unless name
        if (defn=@definitions[name]) && defn[:type]==:macro
          show_macro(name, indent)
        else
          err "Macro #{name} is not defined"
        end
      when 'state'
        show_state(indent)
      when 'value'
        err "Must include name" unless name
        if (defn=@definitions[name]) && defn[:type]==:value
          show_value(name, indent)
        else
          err "Macro #{name} is not defined"
        end
      when 'stack'
        show_stack_trace
      else
        syntax "Bad item type to show #{type}"
      end
    end

    def show_all(indent=0)
      show_state(indent)
      show ''
      show_stack(indent)
      show ''
      show_all_files(indent)
      show ''
      show_all_macros(indent)
      show ''
      show_all_values(indent)
    end

    def show_state(indent=0)
      show 'Formatting state:', indent
      show "          Tabbed? #{self.tabbed.inspect}",    indent+4
      show "          Filled? #{self.fill.inspect}",      indent+4
      show "       Justified? #{self.justify.inspect}",   indent+4
      show "     Line length: #{@line_length}",           indent+4
      show "       Tab stops: #{@tab_stops.inspect}",     indent+4
      show "          Indent: #{@indent}",                indent+4
      show "Temporary indent: #{@next_indent}",           indent+4 if @next_indent!=@indent
      show "     Page length: #{@page_length}",           indent+4
      show "     Page number: #{@page_number}",           indent+4
      show " Page line count: #{@page_line_count}",       indent+4
      show "    Merge string: #{@merge_string.inspect}",  indent+4
      show "     Line buffer: #{@line_buffer.inspect}",   indent+4
      show " Macro arguments: #{self.arguments.inspect}", indent+4
    end

    def show_all_files(indent=0)
      show_title "Files:", indent
      @files.each {|file| show_file_from_defn(file, indent+4) }
    end

    def show_file(name, indent=0)
      fname = name.sub(/^\*/,'')
      return unless f = @files.find{|file| file[:name]==fname}
      show_file_from_defn(f, indent)
    end

    def show_file_from_defn(file, indent=0)
      return unless file
      return if file[:name].nil?
      file_title = "#{file[:number]}: #{file[:name]}"
      file_title += " (#{file[:path]})" unless file[:path].nil? || file[:name]==file[:path]
      if file[:name] == '-'
        show_title file_title, indent
        show "STDOUT", indent+4
      elsif File.exists?(file[:path])
        show_lines file_title, ::File.read(file[:path]), indent
      else
        show_title file_title, indent
        show 'Does not exist', indent+4
      end
    end

    def show_all_macros(indent=0)
      show_title "Macros:", indent
      @definitions.to_a.select{|key, defn| defn[:type]==:macro}.sort_by{|key, defn| key}.each do |key, defn|
        show_macro(key, indent+4)
      end
    end

    def show_macro(name, indent=0)
      return unless defn=@definitions[name]
      return unless defn[:type] == :macro
      show_lines defn[:name], defn[:lines], indent
    end

    def show_all_values(indent=0)
      show_title "Values:", indent
      @definitions.to_a.select{|key, defn| defn[:type]==:value}.sort_by{|key, defn| key}.each do |key, defn|
        show_value(key, indent+4)
      end
    end

    def show_value(name, indent=0)
      return unless defn=@definitions[name]
      return unless defn[:type] == :value
      show "#{defn[:name]} = #{defn[:value].inspect}", indent
    end

    def show_lines(title, text, indent=0)
      text = text.split("\n") if text.is_a?(String)
      show_title title, indent
      line_number_width = text.size.to_s.size
      format_string = "%#{line_number_width}d"
      text.each.with_index {|line, i| show "#{format_string % (i+1)}  #{line}", indent+4 }
    end

    def show_title(title, indent=0)
      show title, indent
      show '-'*(title.size), indent
    end

    def show(text, indent=0)
      log indent_text(text, indent)
    end

    def warn_with_indent(msg, indent=0)
      warn indent_text(msg, indent)
    end
  end
end