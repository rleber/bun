#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class Roff
    class Thing < Hash 
      attr_accessor :roff
      def initialize(roff, options={})
        super()
        @roff = roff
        options.keys.each {|k| self.send("#{k}=", options[k])}
        self[:type] = type
      end

      def type
        self.class.to_s.sub(/.*::/,'').gsub(/(?<!^)([A-Z])/,'_\1').downcase.to_sym
      end

      def method_missing(meth, *args, &blk)
        raise ArgumentError, "Unexpected block for dynamic method #{meth}" if block_given?
        if meth.to_s =~ /(.*)=$/
          raise ArgumentError, "Wrong number of arguments to #{meth} (#{args.size} for 1)" unless args.size==1
          self[$1.to_sym] = args.first
        else
          raise ArgumentError, "Wrong number of arguments to #{meth} (#{args.size} for 0)" unless args.size==0
          self[meth.to_sym]
        end
      end
    end

    class Macro < Thing
      # TODO Wrong approach: push the Macro onto the stack of sources
      def invoke(*arguments)
        macro_context = roff.context_for_macro(self, *arguments)
        Roff.copy_state self, macro_context
        roff.push macro_context
      end
    end

    class Value < Thing
    end

    class Context < Thing
      # The context encapsulates information about what we're roffing:
      #   Current input line
      #   Current input line number
      #   Type of the frame
      #   Name of the frame (e.g. macro name)
      #   Original file source
      #   Starting line number in source file (for error messages)
      #   Arguments
      # There are several kinds of stack frames, e.g.
      #   Text:   We are roffing from text (not a file)
      #   File:   We are roffing from a file
      #   Macro:  We are roffing from a macro
      #   String: We are inserting a string (?)
      def context_type
        type.to_s.sub(/_context/,'').to_sym
      end
    end

    class FileContext  < Context; end
    class TextContext  < Context; end
    class MacroContext < Context; end

    class << self
      # TODO Meaning of to should be:
      #   -      Process to STDOUT
      #   nil    Don't output; return the accumulated result as a string
      #   other  Process to this output path
      def process_file(from, to, options={})
        process_context(to, options) do |roff|
          roff.context_for_file(from)
        end
      end

      def process_text(text, to, options={})
        process_context(to, options) do |roff|
          roff.context_for_text(text)
        end
      end

      def process_context(to, options={}, &blk)
        dir = options.delete(:dir) || Dir.pwd
        Dir.chdir(dir) do
          roff = new(options)
          roff.push yield(roff)
          roff.process(to, options)
        end
      end

      def copy_state(from, to)
        to.parameter_characters = from.parameter_characters.to_s.dup
        to.parameter_escape     = from.parameter_escape.to_s.dup
      end

      def context_attr_reader(*names)
        names.each do |name|
          define_method name do
            current_context.send(name)
          end
        end
      end

      def context_attr_writer(*names)
        names.each do |name|
          define_method "#{name}="  do |value|
            current_context.send("#{name}=", value)
          end
        end
      end

      def context_attr_accessor(*names)
        context_attr_reader(*names)
        context_attr_writer(*names)
      end
    end

    class StackUnderflow < RuntimeError; end

    attr_accessor :context_stack
    attr_reader   :shell
    attr_accessor :line_length
    attr_accessor :indent
    attr_accessor :next_indent
    attr_accessor :line_buffer
    attr_accessor :buffer_stack
    attr_accessor :center
    attr_accessor :fill
    attr_accessor :justify
    attr_accessor :translation
    attr_accessor :parameter_characters
    attr_accessor :parameter_escape
    attr_accessor :insert_characters
    attr_accessor :insert_escape
    attr_accessor :quote_characters
    attr_accessor :quote_escape
    attr_accessor :definitions
    attr_accessor :summary
    attr_accessor :unimplemented_commands
    attr_accessor :command_count
    attr_accessor :merge_string
    attr_accessor :pending_actions
    attr_accessor :page_number
    attr_accessor :output_file_stack
    attr_accessor :files

    DEFAULT_LINE_LENGTH = 60
    IGNORED_COMMANDS = ["af", "bf", "fs", "hc", "hy", "m1", "m2", "m3", "m4", "nd", "ne", "no", "sq"]
    PAGE_NUMBER_CHARACTER = '%'
    PAGE_NUMBER_ESCAPE = '%%'

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
      self.justify = false
      self.center = false
      @random = Random.new
      @translation = []
      parameter_characters = parameter_escape = ''
      @insert_characters = @insert_escape = ''
      @quote_characters = @quote_escape = ''
      @definitions = {}
      set_time
      @context_stack = []
      @unimplemented_commands = []
      @command_count = 0
      @merge_string = ''
      @pending_actions = []
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

    def macro(name)
      defn = @definitions[name]
      defn && defn[:type]==:macro && defn # i.e. return the macro definitiion, if it exists
    end

    def value_of(name)
      defn = @definitions[name]
      return nil unless defn
      if defn[:type] == :macro
        defn[:lines].join("\n")
      else
        defn[:value]
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
      stack_depth == 0
    end

    def stacked?
      !eof?
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
      f = FileContext.new(self, path: path, lines: split_lines(File.read(path)), macro_arguments: [])
      Roff.copy_state self, f if stacked?
      f
    end

    def context_for_text(text)
      t = TextContext.new(self, lines: split_lines(text), macro_arguments: [])
      Roff.copy_state self, t if stacked?
      t
    end

    def context_for_macro(macro, *arguments)
      MacroContext.new(self, macro: macro, name: macro.name, lines: macro.lines, macro_arguments: arguments)
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
    context_attr_reader   :macro_arguments

    def split_lines(text)
      lines = text.to_s.split("\n")
      lines = [''] if lines.size == 0
      lines
    end

    # TODO Should work with a stack of sources
    def process(to='-', options={})
      push_output_file to
      self.next_line_number = 1
      while get_line
        process_line
      end
      flush(justify: false)
    # Cause exceptions to be accompanied by a stack trace
    rescue => e
      log "!Exception occurred: #{e}"
      log_stack_trace('    ')
      raise
    ensure
      dump_summary if summary
      dump_all if summary && @debug
    end

    def process_line(options={})
      line = options[:line] || self.line
      macro_arguments = options[:macro_arguments] || self.macro_arguments || []
      self.expanded_lines = expand(line, macro_arguments: macro_arguments)
      expanded_lines.each.with_index do |expanded_line, i|
        self.expanded_line_number = i+1
        self.expanded_line = expanded_line
        if parse_command(expanded_line)
          process_command
        else
          output_line(expanded_line)
        end
      end
      self.expanded_lines = self.expanded_line = self.expanded_line_number = nil # This is in here in case it's useful for debugging
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
        if action[:count] <= 0
          action[:action].call(line)
          pending_actions.delete_at(i)
        else
          action[:count] -= 1
        end
      end
    end

    def push_pending_action(count, &blk)
      self.pending_actions << {count: count, action: blk}
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

    def expand(line, options={})
      macro_arguments = options[:macro_arguments] || self.macro_arguments || []
      line = line.dup # So we don't change the original version of the line
      original_line = line.dup
      # TODO could move these and only change them when the characters do
      insert_pattern = self.insert_pattern
      insert_escape_pattern = self.insert_escape_pattern
      page_number_pattern = self.page_number_pattern
      parameter_pattern = self.parameter_pattern
      parameter_escape_pattern = self.parameter_escape_pattern
      line = expand_substitutions(line, @insert_characters, insert_pattern, insert_escape_pattern) do |match|
        value_of(match[2..-2]).to_s
      end
      line = expand_substitutions(line, @insert_characters, page_number_pattern, insert_escape_pattern) do |match|
        page_number.to_s
      end
      unless options[:no_parameters]
        line = expand_substitutions(line, parameter_characters, parameter_pattern, parameter_escape_pattern) do |match|
          macro_arguments[(match[1..-1].to_i)-1]
        end
      end
      info "Substitutions: #{original_line} => #{line}" unless original_line == line
      split_lines(line)
    end

    def expand_substitutions(line, chars, pat, escape_pat, &blk)
      line.gsub(pat) {|match| yield(match) }.gsub(escape_pat, chars.to_s)
    end

    def insert_pattern
      substitution_pattern(@insert_characters, @insert_escape, /\(([^)]*)\)/)
    end

    def page_number_pattern
      substitution_pattern(@insert_characters, @insert_escape, /\(#{Regexp.escape(PAGE_NUMBER_CHARACTER)}\)/)
    end

    def insert_escape_pattern
      escape_pattern(@insert_escape)
    end

    def parameter_pattern
      substitution_pattern(parameter_characters, parameter_escape, /(\d+)/)
    end

    def parameter_escape_pattern
      escape_pattern(parameter_escape)
    end

    def substitution_pattern(regular, escape, substitution_pat)
      if regular.to_s == ''
        /\Zx/ # Never matches
      elsif escape.to_s == ''
        /(#{Regexp.escape(regular)}#{substitution_pat})/
      else
        /(#{Regexp.escape(regular)}(?<!#{Regexp.escape(escape)})#{substitution_pat})/
      end
    end

    def escape_pattern(esc)
      if esc.to_s == ''
        /\Zx/ # Never matches
      else
        /#{Regexp.escape(esc)}/
      end
    end
    def display_match(match=$~)
      match.pre_match + '[[' + match[0] + ']]' + match.post_match
    end

    def parse_command(line)
      words = command_words(line)
      if !@literal && words.size>0 && words[0]=~/^\.\S+/ && words
        self.command = words.shift[/^\.(.*)/,1]
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

    def process_command
      write_trace
      self.command_count += 1
      self.overridden_line_number = nil
      if self.respond_to?("process_#{command}")
        begin
          self.send("process_#{command}", *command_arguments)
        rescue ArgumentError => e
          if e.to_s =~ /wrong number of arguments (\(\d+\s+for\s+\d+\))/
            detail = " #{$1}"
          else
            raise
          end
          syntax "Wrong number of arguments#{detail} (Arguments #{command_arguments.inspect})"
        end
      elsif m = macro(command)
        m.invoke(*command_arguments)
      else
        unimplemented
      end
      self.next_line_number = self.overridden_line_number || self.next_line_number
    end

    # .an NAME EXPRESSION
    # Set a value. Expression may be:
    #    n (numeric)  Set the named value to this value
    #    +n           Add n to the named value
    #    -n           Subtract n from the named value
    def process_an(name, expression=nil)
      defn = get_definition(name)
      defn = define_value(name, nil) unless defn
      case expression
      when nil
        # Do nothing; just define value -- which is already done
      when /^\d+$/
        defn.value = expression.to_i
      when /^[+-]\d+$/
        v = defn.value || 0
        defn.value = v + expression.to_i
      else
        syntax "Bad arithmetic expression #{expression.inspect}"
      end
    end

    # .at NAME
    # ...
    # .en NAME
    # Define a macro named NAME. "Invisible" macros (whatever that means), may be
    # surrounded by parentheses.
    def process_at(name)
      tag = name
      name = $1 if name=~/^\((.*)\)$/
      defn = define_macro name
      look_for_en(tag) do |line|
        defn[:lines] +=  expand(line, no_parameters: true)
      end
      defn[:lines].flatten!
    end

    # .br
    # Line break
    def process_br
      force_break
    end

    # .ce n
    # Center the next n lines
    def process_ce(n='1')
      line_count = convert_integer(n, "Line count") if n
      if n
        save_fill = self.fill
        save_justify = self.justify
        push_pending_action(line_count) do |line|
          self.center = false
          self.fill = save_fill
          self.justify = save_justify
        end
      end
      force_break
      self.center = true
      self.fill = false
      self.justify = false
    end

    # .cl n
    # Close file n
    # (Actually, this isn't necessary, the way file access is implemented here)
    def process_cl(fn)
      get_file fn
      # No other action required
    end

    # .debug [SETTING]
    # Set debug mode on or off
    # This is an extension to the original ROFF
    def process_debug(flag='on')
      case flag.downcase
      when "off", "false", "0", "nil"
        @debug = false
      else
        @debug = true
      end
    end

    # .dn n flag
    # ...
    # .en flag
    # Divert output to file n (established by a previous .fa)
    def process_dn(fn, flag)
      file = get_file fn
      push_output_file(file)
      self.buffer_stack.push self.line_buffer
      self.line_buffer = []
      look_for_en(flag) {|line| process_line(line: line) }
      self.line_buffer = self.buffer_stack.pop
      err "!Buffer stack underflow" unless self.line_buffer
      pop_output_file
    end

    # .dump NAME
    # Dump the value of name
    # This is an extension to original ROFF
    def process_dump(name)
      dump_thing(name)
    end

    # .el tag
    # Else clause of if/else conditional (e.g. .if, or .id). Should never occur by itself
    def process_el(tag)
      log "Unmatched .el found:" + stack_trace.first
    end

    # .en tag
    # End of block command (e.g. .if). Should never occur by itself
    def process_en(tag)
      log "Unmatched .en found:" + stack_trace.first
    end

    # .fa n name
    # Attach a file; n is the file number. File names starting with '*' are temporary files
    def process_fa(fn, name)
      ix = convert_integer(fn, "!File number")
      @files[ix] = {name: name.sub(/^\*/,''), path: get_file_name(name), number: ix}
    end

    # .fi
    # Turn filling on (i.e. flow text, word by word)
    def process_fi
      flush unless self.fill
      self.fill = true
      self.center = false
    end

    # .ic CHARS
    # Set insertion characters (e.g. ^^ )
    def process_ic(chars='')
      @insert_characters, @insert_escape = get_escape(chars)
    end

    # .id NAME
    # ...
    # .el NAME (optional)
    # ...
    # .en NAME
    # If name is defined, execute the first part. If it isn't, execute the else
    def process_id(name, flag)
      _process_conditional(flag) { @definitions[name] }
    end

    # .if CONDITION TAG
    # ...
    # .el TAG (optional)
    # ...
    # .en TAG
    # If the condition is true, execute the first part. If it isn't, execute the else
    # Conditions are very simple: of the form <operand><comparison><number>
    def process_if(condition, flag)
      _process_conditional(flag) { evaluate_condition(condition) }
    end

    def evaluate_condition(condition)
      syntax "!Bad .if condition" unless condition =~ /^(.*)(<|=|>|<=|>=|!=)(.*)$/
      op1 = $1.strip
      comparison = $2
      op2 = $3.strip
      op2 = convert_integer(op2, "Second comparison operang")
      # TODO Should this depend on the quoting character?
      # TODO This is temporarily scaffolded and should be fixed
      if op1 =~ /^"(?:[^"]|"")*"$/ # op1 is a quoted string
        log "op1: #{op1.inspect}"
        tweaked_op1 = op1.gsub(/(?<!^)""/,'\\"')
        op1 = begin
          eval(tweaked_op1).size
        rescue SyntaxError => e
          syntax "bad string operand #{op1}"
        end
      # elsif op1 =~ /^[+-]?\d+$/
      else
        op1 = op1.to_i
      # else
      #   syntax "!Bad operand #{op1.inspect} in condition"
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
        found = look_for_el_or_en(flag) {|line| process_line(line: line) }
        look_for_en(flag) if found=='el'
      else
        found = look_for_el_or_en(flag)
        look_for_en(flag) {|line| process_line(line: line) } if found=='el'
      end
    end

    # .in n
    # Set indent
    def process_in(ind)
      self.indent = self.next_indent = convert_relative_integer(self.indent, ind, "Indent")
    end

    # .ju
    # Turn justification on (i.e. even up right edges)
    # TODO Question -- should this force a flush?
    def process_ju
      self.justify = true
      self.center = false
    end

    # .li
    # Treat the next line ltterally
    def process_li
      next_line = get_line
      self.next_line_number += 1
      put_line(next_line) if next_line
    end

    # .ll n
    # Treat the next line ltterally
    def process_ll(len)
      self.line_length = convert_relative_integer(self.line_length, len, "Line length")
    end

    # .mg
    # <merge line>
    # Sets a mask which is merged with the text on output
    # I.e. the merge mask "shows through", wherever there's
    # a space in the output
    def process_mg
      next_line = get_line
      exit if next_line == /^\*+$/
      self.overridden_line_number = self.next_line_number + 1
      self.merge_string = next_line||''
    end

    # .nf
    # Turn off filling (i.e. flowing text)
    def process_nf
      force_break if self.fill
      self.fill = false
    end

    # .pc CHARS
    # Set parameter characters (e.g. @ )
    def process_pc(chars='')
      self.parameter_characters, self.parameter_escape = get_escape(chars)
    end

    # .qc CHARS
    # Set quote characters (e.g. " )
    def process_qc(chars='')
      @quote_characters, @quote_escape = get_escape(chars)
    end

    # .so FILE  or  .so *BUFFER
    # Source from a file or buffer
    def process_so(file)
      original_file = file
      path = get_file_name(file)
      unless File.exists?(path)
        path += '.txt'
        stop "!File #{original_file} does not exist" unless File.exists?(path)
      end
      debug "file: #{file}, path: #{path}"
      self.push context_for_file(path)
    end

    # .sq
    # Turn off justification (i.e. flowing text)
    def process_sq
      force_break if self.justify
      self.justify = false
    end

    # .stop
    # Immediately halt processing
    # This is an extension to original ROFF
    def process_stop(msg=nil)
      stop msg
    end

    # .ti n
    # Set temporary indent
    def process_ti(ind)
      self.next_indent = convert_relative_integer(self.next_indent, ind, "Indent")
    end

    # .tr CHARS
    # Set up a character translation
    # e.g.  .tr ABCD  would translate "A"s to "B"s and "C"s to "D"s
    def process_tr(chars)
      tr1 = ''
      tr2 = ''
      chars.scan(/./).each_slice(2) do |c1, c2|
        c2 ||= ' '
        tr1 += c1
        tr2 += c2
      end
      @translation = [tr1, tr2]
    end

    # .ze STUFF
    # Output a message on $stderr
    def process_ze(*args)
      log args.join(' ')
    end

    # .zz STUFF
    # A comment
    def process_zz(*args)
      # Do nothing
    end

    def write_trace
      info "*Trace: #{stack_trace.first}"
    end

    def unimplemented
      info "!Command #{line} not implemented" unless IGNORED_COMMANDS.include?(command)
      unimplemented_commands << command
    end

    def log(msg)
      puts msg 
    end

    def info(msg)
      log msg if @debug
    end

    def err(msg)
      log msg
      log_stack_trace '    '
      raise RuntimeError, "Error raised" if @debug
      stop
    end

    def log_stack_trace(prefix='')
      stack_trace.each do |context|
        log "#{prefix}#{context}"
      end
    end

    # TODO Stack trace in macros should refer back to the line number in the original file
    def stack_trace
      trace = @context_stack.reverse.map do |context|
        ['Line', context.line_number.to_s, 'in', context.context_type.to_s, context.path, context.name, ':', context.line].compact.join(' ')
      end
      if stacked? && expanded_lines && expanded_lines.size > 1
        trace.unshift ['Line', expanded_line_number, 'in', 'command expansion', ':', expanded_line].join(' ')
      end
      trace
    end

    def convert_relative_integer(base_value, arg, name)
      v = convert_integer(arg, name)
      case arg
      when /^-/
        base_value - v
      when /^\+/
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

    def syntax(msg='')
      err "!Syntax error: #{msg} in #{line}"
    end

    # Encapsulates a common pattern: look for an .en with a matching flag
    def look_for_en(flag, &blk)
      look_for_command('en', '.en', flag, &blk)
    end

    # Encapsulates a common pattern: look for an .el with a matching flag
    def look_for_el(flag, &blk)
      look_for_command('el', '.el', flag, &blk)
    end

    # Encapsulates a common pattern: look for an .el or .en with a matching flag
    def look_for_el_or_en(flag, &blk)
      look_for_command(/^el|en$/, '.el or .en', flag, &blk)
    end
    alias_method :look_for_en_or_el, :look_for_el_or_en

    def look_for_command(pattern, description, flag, &blk)
      while l = get_line do
        info "Looking for #{description} with #{flag}: scanning #{l}"
        lines = expand(l)
        # TODO What happens if we match on the first part of a multi-line?
        lines.each do |l2|
          if parse_command(l2)
            case command
            when pattern # Do it this way, so pattern can be a string or regular expression
              case command_arguments.size
              when 0
                syntax "Missing tag in .#{command}"
              when 1
                if command_arguments[0] == flag || command_arguments[0] == "(#{flag})"
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
        pieces.each do |piece|
          put_piece(piece)
        end
      else
        flush
        put_line line
      end
      invoke_pending_actions(line)
    end

    def break_line(text)
      (text.strip + ' ').scan(/\w+|\s+|./).map {|piece| piece=~/^\s+$/ ? ' ' : piece }
    end

    def put_piece(piece)
      if @line_buffer.join.size + piece.size > net_line_length
        flush
      end
      @line_buffer << piece unless @line_buffer.size==0 && piece=~/^\s+$/
    end

    def net_line_length
      line_length - total_indent
    end

    def total_indent
      [next_indent, 0].max 
    end

    def force_break
      flush(justify: false)
    end

    def flush(options={})
      justify = (options[:justify] || self.justify)
      @temporary_no_justify = false
      unless @line_buffer.size == 0
        if justify
          line = justify_line(@line_buffer)
        elsif self.center
          line = center_line(@line_buffer)
        else
          line = @line_buffer.join
        end
        put_line((' '*total_indent) + transform(line))
      end
      @line_buffer = []
      self.next_indent = self.indent
    end

    def transform(text)
      text = merge(text, merge_string)
      text = text.tr(*@translation) unless @translation.size == 0
      text
    end

    def merge(text, background)
      text ||= ''
      background ||= ''
      res = ''
      [text.size, background.size].max.times do |i|
        text_char = text[i]||' '
        background_char = background[i]||' '
        res += text_char==' ' ? background_char : text_char
      end
      res
    end

    def center_line(buffer)
      trim_buffer buffer
      return '' if buffer.size == 0
      padding = net_line_length - buffer.join.size
      (' '*(padding/2)) + buffer.join
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
          c += (' '*pad1)
          c += ' ' if extra_locations.include?(space_counter)
          space_counter += 1
          c
        else
          c
        end
      end
      padded_buffer.join
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

    # TODO We need a way to put_line to buffers
    # TODO Question: what happens if we start to divert in the middle of a line?
    def put_line(line)
      shell.puts(current_output_file, line)
    end

    def dump_summary(indent=0)
      noteworthy_unimplemented_commands = unimplemented_commands - IGNORED_COMMANDS
      ignored_commands_not_encountered = IGNORED_COMMANDS - unimplemented_commands
      ignored_commands_encountered = IGNORED_COMMANDS - ignored_commands_not_encountered

      put_dump ''
      put_dump "Roff Execution Summary:", indent
      put_dump "#{command_count} commands executed", indent+4
      put_dump "Unimplemented commands:       " + printable_list(noteworthy_unimplemented_commands.uniq.sort),
        indent+4 \
        if noteworthy_unimplemented_commands.size > 0
      put_dump "Ignored commands encountered: " + printable_list(ignored_commands_encountered.uniq.sort),
        indent+4  \
        if ignored_commands_encountered.size > 0
      put_dump "Other ignored commands:       " + printable_list(ignored_commands_not_encountered.uniq.sort),
        indent+4  \
        if ignored_commands_not_encountered.size > 0
    end

    def printable_list(ary)
      ary.map {|ary| ary.to_s}.join(' ')
    end

    def dump_thing(name, indent=0)
      if (f=@files.find {|file| file[:name]==name.sub(/^\*/,'')})
        dump_file_from_defn(f, indent)
      elsif (defn=@definitions[name])
        case defn[:type]
        when :macro
          dump_macro(name, indent)
        when :value
          dump_value(name, indent)
        else
          dump_title "#{name} (Unknown type #{defn[:type].inspect})", indent
          put_dump defn.inspect, indent+4
        end
      else
        put_dump "Dump: #{name} not found", indent
        put_dump "Files: #{@files.compact.map{|f| f[:name]}.sort.join(', ')}", indent+4
        put_dump "Definitions: #{@definitions.keys.sort.join(', ')}", indent+4
      end
    end

    def dump_all(indent=0)
      dump_all_files(indent)
      put_dump ''
      dump_all_macros(indent)
      put_dump ''
      dump_all_values(indent)
    end

    def dump_all_files(indent=0)
      dump_title "Files:", indent
      @files.each {|file| dump_file_from_defn(file, indent+4) }
    end

    def dump_file(name, indent=0)
      fname = name.sub(/^\*/,'')
      return unless f = @files.find{|file| file[:name]==fname}
      dump_file_from_defn(f, indent)
    end

    def dump_file_from_defn(file, indent=0)
      return unless file
      return if file[:name].nil?
      file_title = "#{file[:number]}: #{file[:name]}"
      file_title += " (#{file[:path]})" unless file[:path].nil? || file[:name]==file[:path]
      if file[:name] == '-'
        dump_title file_title, indent
        put_dump "STDOUT", indent+4
      elsif File.exists?(file[:path])
        dump_lines file_title, File.read(file[:path]), indent
      else
        dump_title file_title, indent
        put_dump 'Does not exist', indent+4
      end
    end

    def dump_all_macros(indent=0)
      dump_title "Macros:", indent
      @definitions.to_a.select{|key, defn| defn[:type]==:macro}.sort_by{|key, defn| key}.each do |key, defn|
        dump_macro(key, indent+4)
      end
    end

    def dump_macro(name, indent=0)
      return unless defn=@definitions[name]
      return unless defn[:type] == :macro
      dump_lines defn[:name], defn[:lines], indent
    end

    def dump_all_values(indent=0)
      dump_title "Values:", indent
      @definitions.to_a.select{|key, defn| defn[:type]==:value}.sort_by{|key, defn| key}.each do |key, defn|
        dump_value(key, indent+4)
      end
    end

    def dump_value(name, indent=0)
      return unless defn=@definitions[name]
      return unless defn[:type] == :value
      put_dump "#{defn[:name]} = #{defn[:value].inspect}", indent
    end

    def dump_lines(title, text, indent=0)
      text = text.split("\n") if text.is_a?(String)
      dump_title title, indent
      line_number_width = text.size.to_s.size
      format_string = "%#{line_number_width}d"
      text.each.with_index {|line, i| put_dump "#{format_string % (i+1)}  #{line}", indent+4 }
    end

    def dump_title(title, indent=0)
      put_dump title, indent
      put_dump '-'*(title.size), indent
    end


    def put_dump(text, indent=0)
      log((' '*indent)+text)
    end
  end
end