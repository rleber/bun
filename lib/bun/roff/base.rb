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
    attr_accessor :parameter_character
    attr_accessor :parameter_escape
    attr_accessor :expand_parameters
    attr_accessor :expand_substitutions
    attr_accessor :insert_character
    attr_accessor :insert_escape
    attr_accessor :quote_character
    attr_accessor :quote_escape
    attr_accessor :definitions
    attr_accessor :summary
    attr_accessor :unimplemented_requests
    attr_accessor :processed_requests
    attr_accessor :request_count
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
    IGNORED_REQUESTS = %w{bf fs hc hy nc nd no po pw uc}
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
      @parameter_character = @parameter_escape = ''
      @expand_parameters = true
      @expand_substitutions = true
      @insert_character = @insert_escape = ''
      @quote_character = @quote_escape = ''
      @definitions = {}
      set_time
      @context_stack = [BaseContext.new(self)]
      @unimplemented_requests = []
      @processed_requests = []
      @request_count = 0
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
      define_register 'year', now.year
      define_register 'mon',  now.month
      define_register 'day',  now.day
      define_register 'hour', now.hour
      define_register 'min',  now.min
      define_register 'sec',  now.sec
    end

    def define(name, obj)
      name = name.value unless name.is_a?(String)
      @definitions[name] = obj
    end

    def defined?(name)
      name = name.value unless name.is_a?(String)
      @definitions[name]
    end
    alias_method :get_definition, :defined?

    def define_register(name, lines=[], options={})
      v = Register.new(self)
      name = name.value unless name.is_a?(String)
      v.name = name
      if lines.is_a?(Integer)
        v.lines = nil
        v.value = lines
        v.data_type = :number
      else
        v.lines = lines
        v.value = nil
        v.data_type = :text
      end
      v.merge!(options)
      define name, v
    end

    def register_definition(name)
      @definitions[name]
    end

    def value_of(name)
      name = name.value unless name.is_a?(String)
      defn = @definitions[name]
      return nil unless defn
      if defn[:data_format] == :number
        v = defn[:value].to_s
        if defn[:format]
          v = merge(right_justify_text(v.to_s, defn[:format].size), defn[:format])
        end
      else
        v = defn[:lines].join("\n")
      end
      v
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
      f = FileContext.new(self, path: path, lines: split_lines(::File.read(path)), register: self.register)
      Roff.copy_state self, f if stacked?
      f
    end

    def context_for_text(text)
      t = TextContext.new(self, lines: split_lines(text), register: self.register)
      Roff.copy_state self, t if stacked?
      t
    end

    def context_for_register(register, *arguments)
      RegisterContext.new(self, register: register, name: register.name, lines: register.lines, arguments: arguments)
    end

    context_attr_accessor :line_number
    context_attr_accessor :next_line_number
    context_attr_accessor :overridden_line_number
    context_attr_accessor :line
    context_attr_accessor :expanded_lines
    context_attr_accessor :parsed_line
    context_attr_accessor :expanded_line
    context_attr_accessor :expanded_line_number
    context_attr_accessor :request
    context_attr_accessor :request_arguments
    context_attr_accessor :parameter_character
    context_attr_accessor :parameter_escape
    context_attr_reader   :context_type
    context_attr_reader   :name
    context_attr_reader   :path
    context_attr_reader   :lines
    context_attr_reader   :register
    context_attr_reader   :arguments
    context_attr_reader   :at_bottom

    def split_parsed_lines(parsed_text)
      split_tokens_at(parsed_text) {|t| t.type==:end_of_line}
    end

    def split_tokens_at(parsed_text, &blk)
      lines = []
      parsed_text.each do |token|
        lines << [] if lines.size == 0
        lines.last << token
        lines << [] if yield(token)
      end
      lines.pop if parsed_text.size > 0 && parsed_text.last.type == :end_of_line
      lines
    end

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
        self.parsed_line = parse(self.line)
        self.expanded_lines = expand(self.parsed_line)
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
    rescue BadExpression => e
      log e
    rescue => e
      log "!Exception occurred: #{e}"
      show_stack_trace('    ')
      raise
    ensure
      show_summary if summary
      show_all if summary && @debug
    end

    def process_line(line)
      if parse_request(line)
        process_request
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

    def parse_request(line)
      words = request_words(line)
      if words.size>0 && words[0].type == :request_word
        self.request = words.shift
        self.request_arguments = words 
        self.request
      else
        self.request = self.request_arguments = nil
      end
    end

    def request_words(line)
      line.map{|word| word.compressed }.compact
    end

    def process_request
      write_trace "Execute", [request.text,*(request_arguments.map{|a| a.text })].join(' ')
      self.request_count += 1
      self.overridden_line_number = nil
      meth = "#{request.value}_request"
      if self.respond_to?(meth)
        # send_arguments = request_arguments[0,self.method(meth).arity.abs]
        send_arguments = request_arguments
        begin
          self.processed_requests << request
          self.send(meth, *send_arguments)
        rescue ArgumentError => e
          if !@debug && e.to_s =~ /`#{Regexp.escape(meth.to_s)}'.*wrong number of arguments (\(\d+\s+for\s+\d+\))/
            detail = " #{$1}"
          else
            raise
          end
          syntax "Wrong number of arguments#{detail} (Arguments #{request_arguments.inspect})"
        end
      elsif m = register_definition(request)
        m.invoke(*request_arguments)
      else
        unimplemented
      end
      self.next_line_number = self.overridden_line_number || self.next_line_number
    end

    def line_part_spec
      line_parts = expanded_line
      line_parts.shift
      line_parts.shift while line_parts.size > 0 && line_parts.first.type==:whitespace
      delimiter = line_parts.first
      parts = split_tokens_at(line_parts) {|t| t.type==delimiter.type && t.value == delimiter.value}
      parts.shift
      (parts.map{|part| part[0..-2].map{|t| t.value}.join } + ['', '', ''])[0,3] \
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

    def write_trace(flag="Execute", expanded_request)
      position, original_request = stack_trace.first.split(/\s*:\s*/)
      out = if expanded_request == original_request
        expanded_request
      else
        "#{expanded_request} <= #{original_request}"
      end
      info "*#{'%-25s'%flag} #{'%-60s' % out} @ #{position}"
    end

    def unimplemented
      unimplemented_requests << request
    end

    def log(msg)
      warn msg 
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

    # TODO Stack trace in registers should refer back to the line number in the original file
    def stack_trace
      trace = @context_stack.reverse.map do |context|
        next if context.context_type == :base
        ['Line', context.line_number.to_s, 'in', context.context_type.to_s, context.path, context.name, ':', context.line].compact.join(' ')
      end.compact
      if stacked? && expanded_lines && expanded_lines.size > 1
        trace.unshift ['Line', expanded_line_number, 'in', 'request expansion', ':', expanded_line].join(' ')
      end
      trace
    end

    def convert_expression(base_value, *args)
      tokens = args.shift
      return tokens if tokens.is_a?(Integer) # Allow easy default value setting
      tokens = [tokens] unless tokens.is_a?(Array)
      tokens = preprocess_expression(tokens)
      label = args.shift || "?"
      ensure_not_end_of_line tokens, BadExpression, "Empty expression in #{label}"
      if tokens.first.type == :operator
        value = base_value
      else
        value = get_expression_value(tokens.first)
        tokens.shift
      end
      while tokens.size >0 && tokens.first.type != :end_of_line
        input_error BadExpression, "Expecting operator in #{label}, found #{tokens.first.type} #{tokens.first.text.inspect}", at: tokens.first.interval.begin \
          unless valid_operator?(tokens.first)
        operator = tokens.shift
        ensure_not_end_of_line tokens, BadExpression, "Empty expression in #{label}"
        value = perform_operator(value, operator, get_expression_value(tokens.first, label), label)
        tokens.shift
      end
      value
    end

    # Kludgy; separate grammar for expressions?
    def preprocess_expression(expression)
      loop do
        changes = 0
        new_expression = []
        expression.each do |token|
          if token.type == :word
            input_error BadExpression, "Found strange character #{token.text[0].inspect} in expression", at: token.interval.begin \
              unless token.text[0] == 'l' || token.text[0] == 's'
            if token.text.size == 1
              new_expression << token
            else
              new_expression << ParsedNode.create(:word, text: token.text[0], interval: (token.interval.begin...(token.interval.begin+2)))
              changes += 1
              input_error BadExpression, "Found strange character #{token.text[1].inspect} in expression", at: token.interval.begin+1 \
                unless token.text[1] =~ /[0-9]/
              next_token = token.text[1..-1][/^([0-9]+)/,1]
              remainder = $'
              new_expression << ParsedNode.create(:number, text: next_token, interval: (token.interval.begin+1)...(token.interval.begin+1+next_token.size))
              new_expression << ParsedNode.create(:word, text: remainder, interval: (token.interval.begin+1+next_token.size)...(token.interval.end)) \
                if remainder.size > 0
            end
          else
            new_expression << token
          end
        end
        expression = new_expression
        break if changes == 0
      end
      expression
    end

    def valid_operator?(token)
      %w{l s + - * / < > =}.include?(token.output_text)
    end

    def get_expression_value(arg, label="?")
      case arg.type
      when :number
        arg.value
      when :quoted_string
        arg.value.size
      else
        raise BadExpression, "Invalid operand in #{label}: #{arg.text}"
      end
    end

    def perform_operator(value1, operator, value2, label="?")
      case operator.value.to_s
      when "+"
        value1 + value2
      when "-"
        value1 - value2
      when "*"
        value1 * value2
      when "/"
        value1 / value2
      when "<"
        (value1 < value2) ? 1 : 0
      when "="
        (value1 == value2) ? 1 : 0
      when ">"
        (value1 > value2) ? 1 : 0
      when "l"
        [value1, value2].max
      when "s"
        [value1, value2].min
      else
        input_error BadExpression, "Unexpected operator in #{label}: #{operator}", at: operator.interval.begin
      end
    end

    def convert_string(arg, name)
      return arg if arg.is_a?(String) # Allow easy default value setting
      arg.output_text
    end

    def convert_integer(arg, name)
      return arg if arg.is_a?(Integer) # Allow easy default value setting
      err "!#{name} must be an integer" unless arg.type == :number
      i = arg.value
      err "!#{name} can't be negative" if i<0
      i 
    end

    def ensure_not_end_of_line(*args)
      tokens = args.shift
      if tokens.size == 0
        at = self.line.size
      elsif tokens.first.type == :end_of_line
        at = tokens.first.interval.begin 
      else
        return
      end
      input_error(*args, at: at)
    end

    def input_error(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      case args.size
      when 0
        klass = RuntimeError
        msg = ""
      when 1
        klass = RuntimeError
        msg = args[0]
      else
        klass = args[0]
        msg = args[1]
      end
      msg += "\n" if msg.size>0
      msg += "    #{line}"
      msg += "\n    #{' '*options[:at]}^" if options[:at]
      raise klass, msg
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
      look_for_request('en', description, flag, options, &blk)
    end

    # Encapsulates a common pattern: look for an .el with a matching flag
    def look_for_el(description, flag, options={}, &blk)
      look_for_request('el', description, flag, options, &blk)
    end

    # Encapsulates a common pattern: look for an .el or .en with a matching flag
    def look_for_el_or_en(description, flag, options={}, &blk)
      look_for_request(/^el|en$/, description, flag, options, &blk)
    end
    alias_method :look_for_en_or_el, :look_for_el_or_en

    def look_for_request(pattern, description, flag, options={}, &blk)
      flag = $1 if flag=~/^\((.*)\)$/
      expand_substitutions = options[:expand_substitutions]==true || (options[:expand_substitutions].nil? && self.expand_substitutions)
      while l = get_line do
        parsed_line = parse(l)
        write_trace description, l if description
        if options[:no_expand]
          lines = [parsed_line]
        else
          lines = expand(parsed_line, expand_substitutions: expand_substitutions)
        end
        # TODO What happens if we match on the first part of a multi-line?
        lines.each do |l2|
          if parse_request(l2)
            case request
            when pattern # Do it this way, so pattern can be a string or regular expression
              case request_arguments.size
              when 0
                syntax "Missing tag in .#{request}"
              when 1
                request_flag = request_arguments.first
                # Is this right?
                request_flag = expand($1, expand_parameters: true, expand_substitutions: expand_substitutions)[0] if request_flag =~ /^\((.*)\)$/ 
                if request_flag == flag
                  self.request_count += 1
                  return request
                end
                yield(l2) if block_given?
              else
                syntax "Extra arguments in .#{request}"
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

    def output_line(line)
      if self.fill
        return if line.size == 0
        force_break if line.first.type == :whitespace
        line.each do |piece|
          fill_piece(piece)
        end
      else
        force_break if @line_buffer.size > 0
        self.line_buffer = line.map{|piece| piece.output_text } # Do it this way to force centering, translation, etc.
        flush
      end
      invoke_pending_actions(line)
    end

    LINE_ENDINGS = ['.', ':', '!', '?']

    def fill_piece(piece)
      case piece.type
      when :quoted_string
        save_quote_character = quote_character
        self.quote_character = nil
        parts = parse(piece.text)
        self.quote_character = save_quote_character
        parts.each {|token| fill_piece(token)}
      when :parenthesized_sentence
        piece.value.each {|token| fill_piece(token)}
      else
        fill_atom(piece)
      end
    end

    def fill_atom(piece)
      case piece.type
      when :whitespace
        return if @line_buffer.size==0 # Don't start lines with spaces
        chunk = ' '
      when :end_of_line
        return if @line_buffer.size==0 # Don't start lines with spaces
        return if @line_buffer.last==' ' # Not necessary to add to spacing
        chunk = LINE_ENDINGS.include?(@line_buffer.last) ? '  ' : ' '
      else
        chunk = piece.output_text 
      end
      next_buffer = @line_buffer + [chunk]
      next_buffer_size = next_buffer.join.size
      if next_buffer_size > net_line_length # Line overflow
        if self.hyphenation_mode==0 || piece.type != :word
          next_buffer = [chunk]
        # TODO Check for hyphenation character
        else # Attempt to hyphenate
          minimum_suffix_size = next_buffer_size - net_line_length + HYPHEN.size
          hyphenation_suffix = self.hyphenator.sentence_suffix(next_buffer, minimum_suffix_size)
          if hyphenation_suffix == '' || hyphenation_suffix == chunk
            next_buffer = [chunk]
          else
            @line_buffer << (chunk[0...-(hyphenation_suffix.size)]+HYPHEN)
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
        if self.fill
          if justify
            line = justify_line(@line_buffer)
          else
            trim_buffer @line_buffer
            line = @line_buffer.join
          end
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
      return buffer.join if padding < 0
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
      left_trim_buffer buffer
      right_trim_buffer buffer
    end

    def left_trim_buffer(buffer)
      while buffer.size>0 && buffer.first =~ /^\s*$/
        buffer.delete_at(0)
      end
    end

    def right_trim_buffer(buffer)
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
      shell.puts(current_output_file, line.rstrip)
    end

    def show_summary(indent=0)
      unimplemented_requests = self.unimplemented_requests.uniq
      processed_requests = self.processed_requests.uniq
      noteworthy_unimplemented_requests = unimplemented_requests - IGNORED_REQUESTS
      ignored_requests_implemented = IGNORED_REQUESTS & processed_requests
      ignored_requests_not_encountered = IGNORED_REQUESTS - unimplemented_requests - ignored_requests_implemented
      ignored_requests_encountered = IGNORED_REQUESTS - ignored_requests_not_encountered - ignored_requests_implemented

      warn ''
      warn_with_indent "Roff Execution Summary:", indent
      warn_with_indent "#{request_count} requests executed", indent+4
      warn_with_indent "Unimplemented requests:       " + printable_list(noteworthy_unimplemented_requests.sort),
        indent+4 \
        if noteworthy_unimplemented_requests.size > 0
      warn_with_indent "Ignored requests encountered: " + printable_list(ignored_requests_encountered.uniq.sort),
        indent+4  \
        if ignored_requests_encountered.size > 0
      warn_with_indent "Ignored requests implemented: " + printable_list(ignored_requests_implemented.uniq.sort),
        indent+4  \
        if ignored_requests_implemented.size > 0
      warn_with_indent "Other ignored requests:       " + printable_list(ignored_requests_not_encountered.uniq.sort),
        indent+4  \
        if ignored_requests_not_encountered.size > 0
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
      when 'register'
        err "Must include name" unless name
        if (defn=@definitions[name]) && defn[:type]==:register
          show_register(name, indent)
        else
          err "Register #{name} is not defined"
        end
      when 'state'
        show_state(indent)
      when 'value'
        err "Must include name" unless name
        if (defn=@definitions[name]) && defn[:type]==:value
          show_value(name, indent)
        else
          err "Register #{name} is not defined"
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
      show_all_registers(indent)
      show ''
      show_all_values(indent)
    end

    def show_state(indent=0)
      show 'Formatting state:', indent
      show "            Tabbed? #{self.tabbed.inspect}",    indent+4
      show "            Filled? #{self.fill.inspect}",      indent+4
      show "         Justified? #{self.justify.inspect}",   indent+4
      show "       Line length: #{@line_length}",           indent+4
      show "         Tab stops: #{@tab_stops.inspect}",     indent+4
      show "            Indent: #{@indent}",                indent+4
      show "  Temporary indent: #{@next_indent}",           indent+4 if @next_indent!=@indent
      show "       Page length: #{@page_length}",           indent+4
      show "       Page number: #{@page_number}",           indent+4
      show "   Page line count: #{@page_line_count}",       indent+4
      show "      Merge string: #{@merge_string.inspect}",  indent+4
      show "       Line buffer: #{@line_buffer.inspect}",   indent+4
      show "Register arguments: #{self.arguments.inspect}", indent+4
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

    def show_all_registers(indent=0)
      show_title "Macros:", indent
      @definitions.to_a.select{|key, defn| defn[:type]==:register}.sort_by{|key, defn| key}.each do |key, defn|
        show_register(key, indent+4)
      end
    end

    def show_register(name, indent=0)
      return unless defn=@definitions[name]
      return unless defn[:type] == :register
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