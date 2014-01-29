#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO Items
#   BUGS:
#   Change meaning of .hy N
#       .hy 0  No hyphenation
#       .hy 1  Hyphenate at hyphens and hyphenation characters
#       .hy 2  (Default) Allow hyphenation before certain suffixes
#       .hy 3  "Maximum hyphenation" (between certain pairs of letters)
#   Tabbing is relative to the current page offset and indentation
#   Merge patterns have "locked in" offsets, based on the values of .po, .in, and .ll
#   It appears that .ta should NOT be zero-based (?!)
#   Treatment of extra tabs
#   Treatment of tabs (i.e. automatic tabbing mode if there are tabs in the output)
#   Set .m1, .m2, .m3, and .m4 defaults properly: m1=4, m2=2, m3=1, m4=4
#   Current .sq is really .nj
#   Pagination should not print titles or footers that don't fit in the margins
#   .pl 0 should turn of page breaks (except for .bp requests)
#   Change "command" to "request" throughout
#   .at should "ruthlessly suppress newlines wherever possible", in particular at end
#   Insertions may have parameters
#   Insertions may be nested
#   Commands may appear in insertions (and function)
#   Insertions work in .li text
#   ^(name ...) should result in "0" if name is not defined, and should produce a warning
#   .name ... should result in a warning
#   .he and .fo should insist that the delimiter is a non-alphanumeric
#   Does .ic with no arguments work?
#   Check how the ^^ pattern works
#   Redefining a register should throw an error
#   .at should "lock in" which lines are commands
#   Parameter substitution should still work after .pc turns off the parameter character
#   Whitespace at the start of a line should cause an automatic line break
#   .an NAME (i.e. with no second parameter) sets NAME to 1 (!)
#   Do we allow "_", "%", and "#" in register names?
#   If .qc is set to something odd, do .if and .an expressions work?
#   Are register names case-insensitive?
#   Do we allow parentheses around register names in .an, .af, etc.?
#   Two blanks after ":", ".", "?", and "!" at the end of a line
#   Do tabs work as command/argument separators?
#   Confirm line break behavior of all commands
#   Confirm all commands that can take expressions
#   Does .ce 0 work properly (i.e. turn off centering)?
#   .ti should shift the results of an immediately preceding .ce
#   Fix meaning of .m1, .m2, .m3, .m4, .sq
#   Fix meaning of .ne to account for spacing
#   Fix line spacing at bottom of pages (i.e. no blank lines at top of next page)
#   .sp should never insert blank lines at the top of a page
#   Props list is not working
#   Are some music cues, i.e. [M-2], etc., missing?
#   Should there be SFX and sound cues?
#   Inserts extra spaces at word ends (e.g. "((\nSFX\}"  generates "( SFX )". It should be "(SFX)")
#   Are we still spreading out spacing on final lines of paragraphs?
#   Props list line references aren't working. This is because expanding still isn't working quite right.
#     It should expand a parameter reference or an insertion, but not both in the same text, I think. Also,
#     that may mean that the settings for "don't expand" may not be set right, currently.
#   .sp n should not insert blank lines at the top of a page
#   roff only recognizes hyphenation modes 0-3
#   Check functioning of .if E (E is tested vs. zero)
#   Stacking of file attachments
#
#   IMPROVEMENTS:
#   Other special registers: "%", "#", "%in", "%po", "%ll", "%pw", "%pl", "%ls", "%m1"-"%m4",
#       "%amon", "%wday", "%tf"
#   Other arithmetic operators ("*", "/") in .an (e.g. .an foo *5)
#   Relational operators ("<", "=", and ">") in .an (set value to 1 if true, 0 if not)
#   "l" and "s" ("larger" and "smaller") operators
#   Generalized value of strings in .an and .if expressions (i.e. replaced with size)
#   Allow multiple operators in expressions
#   Turn on/off pagination
#   Specify files for diversions on the command line
#   Implement notes (.no and .nd)
#   Optional second parameter to .ti
#   Change .stop to .ab for compatibility
#   Add optional N to .mg (Nth merge mask)
#   Add optional N to .he and .fo (Nth header or footnote)
#   Implement improved formatting ("i", "I", "a", "A", "o", "O", "z+1")
#   Eliminate distinction between macros and values (called "registers" in tf)
#   Improved line breaking: xxx', 'xxx, xxx), (xxx, hyphenation
#   Justification is generally turned off most of the time. (Although this may be correct.)
#   Error messages should reference original file names and line numbers
#   =prefix for disabling expansion
#   inject method for injecting input lines; refactor multi-line expand using this and =
#   Additional commands, e.g.
#     .st                  Pause (if outputing to a terminal)
#     .ix N                Synonym for .di
#     .nx                  Synonym for .dn
#     .bf N                Bold face
#     .pw N                Set page width
#     .ig TAG ... .en TAG  Ignore input
#     .po N                Page offset
#     .bl N                N blank lines
#     .bp                  Start new page
#     .pa +N               Same as .bp, but set new page number
#     .cc CHAR             Set control character
#     .ds                  Double space
#     .ss                  Single space
#     .ef, .eh, .of, .oh   Even and odd page titles
#     .hx                  Suppress header titles
#     .ix n                .in without line break
#     .ln, .n0, .n1, .n2   Line numbering
#     .ro, .ar             Roman and Arabic page numbering
#     .zt NAME             Delete macro
#     .cs CHAR             Set case escape character (overrides .uc and .lc)
#     .db CHAR             Use CHAR as a padding character for proportional spacing
#     .dc CHAR N [STRING]  Sets the width of CHAR in proportional spacing; replace CHAR with STRING on output
#     .ep                  Begin an even page
#     .op                  Begin an odd page
#     .ff N                Set "line number of top of form"
#     .fn TAG ... .en TAG  Divert output to footnotes (note footnotes maintain their own context)
#     .ib CHAR             Convert CHAR to blank on input (this may have been added post-FASS)
#     .lv N                Leave n blank lines; wait until next page if necessary
#     .np N                Do not print next N pages
#     .ns N                No filling in first N characters of next line
#     .nt                  Return line number of next trap on page
#     .nu                  No first character underlining
#     .pr N                Print requests in column N -- i.e. trace
#     .ps N                Print file/line number information in column N
#     .sa NAME             Save register on stack
#     .sk N                Skip at next new page to page N
#     .sl N                Control formfeeds (0 = don't insert formfeeds; 1 = do)
#     .sy COMMAND          Execute system command
#     .tb                  Table break
#     .tc CHAR             Set "extra" tab character
#     .td N                Delete all traps for line N
#     .te N                Enable/disable trap processing
#     .tn CHARS            Set escape sequence for normal output on output device
#     .tf CHARS            Set escape sequence for bold face on output device
#     .tu CHARS            Set escape sequence for underlining on output device
#     .tl CHARS            Set escape sequence for bold face + underline on output device
#     .tp N NAME           When line N is reached, "trap goes off", executing the named register
#     .tt TAG ... .en TAG  Divert output to table
#     .uf                  Underline first character of every input line
#     .ul N                Underline next N lines
#     .zt NAME             Pop saved value for NAME
#
# EXTENSIONS
#     Generalized relational operators
#     Generalized Ruby expressions
#     Allow spaces after control character
#     Mode setting comment


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
      attr_accessor :macro

      def initialize(roff, options={})
        super
        @macro = options[:macro]
      end

      def at_bottom
        false
      end

      def arguments
        macro.arguments
      end

      def context_type
        type.to_s.sub(/_context/,'').to_sym
      end
    end

    class BaseContext  < Context
      def macro
        self
      end

      def at_bottom
        true
      end

      def arguments
        nil
      end
    end
    class FileContext  < Context; end
    class TextContext  < Context; end
    class MacroContext < Context
      attr_accessor :arguments
      def initialize(roff, options={})
        super
        @arguments = options[:arguments]
      end

      def macro
        self
      end
    end

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
    attr_accessor :tabbed
    attr_accessor :line_spacing
    attr_accessor :page_length
    attr_accessor :page_top_margin
    attr_accessor :page_bottom_margin
    attr_accessor :page_left_margin
    attr_accessor :page_right_margin
    attr_accessor :page_line_count
    attr_accessor :page_headers
    attr_accessor :page_footers
    attr_accessor :pages_built
    attr_accessor :translation
    attr_accessor :hyphenation_character
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
    attr_accessor :page_number
    attr_accessor :output_file_stack
    attr_accessor :files

    DEFAULT_LINE_LENGTH = 65
    DEFAULT_PAGE_LENGTH = 66
    DEFAULT_PAGE_HEADERS = []
    DEFAULT_PAGE_FOOTERS = []
    IGNORED_COMMANDS = %w{bf fs hc hy nc nd no po pw uc}
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
      self.tabbed = false
      @line_spacing = 1
      @page_length = DEFAULT_PAGE_LENGTH
      @page_top_margin = 0
      @page_bottom_margin = 0
      @page_left_margin = 0
      @page_right_margin = 0
      @page_line_count = 0
      @pages_built = 0
      @page_headers = DEFAULT_PAGE_HEADERS.compact
      @page_footers = DEFAULT_PAGE_FOOTERS.compact
      @random = Random.new
      @translation = []
      @hyphenation_character = ''
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
      flush(justify: false)
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
      macro_arguments = self.arguments
      line = line.dup # So we don't change the original version of the line
      original_line = line.dup
      # TODO could move these and only change them when the characters do
      insert_pattern = self.insert_pattern
      insert_escape_pattern = self.insert_escape_pattern
      page_number_pattern = self.page_number_pattern
      parameter_pattern = self.parameter_pattern
      parameter_escape_pattern = self.parameter_escape_pattern
      changes = 0
      if (self.expand_parameters || options[:expand_parameters]) \
          && (options[:expand_parameters]!=false) \
          && macro_arguments
        line = expand_item(line, parameter_characters, parameter_pattern, parameter_escape_pattern) do |match|
          changes += 1
          macro_arguments[(match[1..-1].to_i)-1]
        end
      end
      if (self.expand_substitutions || options[:expand_substitutions]) \
          && options[:expand_substitutions]!=false
        line = expand_item(line, @insert_characters, insert_pattern, insert_escape_pattern) do |match|
          v = value_of(match[2..-2])
          if v.nil?
            match
          else
            changes += 1
            v.to_s
          end
        end
      end
      line = expand_item(line, @insert_characters, page_number_pattern, insert_escape_pattern) do |match|
        changes += 1
        page_number.to_s
      end
      split_lines(line)
    end

    def expand_item(line, chars, pat, escape_pat, &blk)
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

    def command_escape(string)
      string=~/\s/ ? string.inspect : string
    end

    def process_command
      write_trace "Execute", ['.'+command,*(command_arguments.map{|a| command_escape(a)})].join(' ')
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

    # .af NAME FORMAT
    # Assign format to variable
    # Formats are as a mask, e.g. '001' would be a three character format, with leading zeroes
    def af_command(name, format, *_)
      err "!Variable #{name} not defined" unless @definitions[name]
      err "!#{name} is not a variable" unless @definitions[name][:type] == :value
      @definitions[name][:format] = format
    end

    # .an NAME EXPRESSION
    # Set a value. Expression may be:
    #    n (numeric)  Set the named value to this value
    #    +n           Add n to the named value
    #    -n           Subtract n from the named value
    def an_command(name, expression=nil, *_)
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
    def at_command(name, *_)
      tag = name
      name = $1 if name=~/^\((.*)\)$/
      defn = define_macro name
      look_for_en(nil, tag) do |line|
        expanded_lines = expand(line)
        if @debug
          expanded_lines.each.with_index do |l, i|
            out = "#{defn[:lines].size+i+1}: #{l} <= #{line}"
            out += " [part #{i+1}]" if expanded_lines.size>1
            show out, 4
          end
        end
        defn[:lines] += expanded_lines
      end
      defn[:lines].flatten!
    end

    # .br
    # Line break
    def br_command(*args)
      force_break
    end

    # .ce n
    # Center the next n lines
    def ce_command(n=nil, *_)
      line_count = convert_integer(n, "Line count") if n
      if n
        save_fill = self.fill
        save_justify = self.justify
        save_tabbed = self.tabbed
        push_pending_action(line_count) do |line|
          self.center = false
          self.fill = save_fill
          self.justify = save_justify
          self.tabbed = save_tabbed
        end
      end
      force_break
      self.center = true
      self.fill = false
      self.justify = false
      self.tabbed = false
    end

    # .cl n
    # Close file n
    # (Actually, this isn't necessary, the way file access is implemented here)
    def cl_command(fn, *_)
      get_file fn
      # No other action required
    end

    # .debug [SETTING]
    # Set debug mode on or off
    # This is an extension to the original ROFF
    def debug_command(flag='on', *_)
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
    def dn_command(fn, flag, *_)
      file = get_file fn
      push_output_file(file)
      self.buffer_stack.push self.line_buffer
      self.line_buffer = []
      look_for_en(nil,flag, expand_substitutions: false) do |line|
        write_trace("Divert", line)
        put_line(line)
      end
      self.line_buffer = self.buffer_stack.pop
      err "!Buffer stack underflow" unless self.line_buffer
      pop_output_file
    end

    # .el tag
    # Else clause of if/else conditional (e.g. .if, or .id). Should never occur by itself
    def el_command(tag, *_)
      log "Unmatched .el found:" + stack_trace.first
    end

    # .en tag
    # End of block command (e.g. .if). Should never occur by itself
    def en_command(tag, *_)
      log "Unmatched .en found:" + stack_trace.first
    end

    # .fa n name
    # Attach a file; n is the file number. File names starting with '*' are temporary files
    def fa_command(fn, name, *_)
      ix = convert_integer(fn, "!File number")
      @files[ix] = {name: name.sub(/^\*/,''), path: get_file_name(name), number: ix}
    end

    # .fi
    # Turn filling on (i.e. flow text, word by word)
    def fi_command(*_)
      flush unless self.fill
      self.fill = true
    end

    # .fo '...'...'...'
    # Set page footer
    # In the example above, "'" could be any character
    def fo_command(*args)
      @page_footers = [line_part_spec]
    end

    # .hc CHAR
    # Set hyphenation marker. Roff will attempt to hyphenate words here
    def hc_command(char, *_)
      @hyphenation_character = char
    end

    # .he '...'...'...'
    # Set page heading
    # In the example above, "'" could be any character
    def he_command(*args)
      @page_headers = [line_part_spec]
    end

    # .ic CHARS
    # Set insertion characters (e.g. ^^ )
    def ic_command(chars='', *_)
      @insert_characters, @insert_escape = get_escape(chars)
    end

    # .id NAME
    # ...
    # .el NAME (optional)
    # ...
    # .en NAME
    # If name is defined, execute the first part. If it isn't, execute the else
    def id_command(name, flag, *_)
      _process_conditional(flag) { @definitions[name] }
    end

    # .if CONDITION TAG
    # ...
    # .el TAG (optional)
    # ...
    # .en TAG
    # If the condition is true, execute the first part. If it isn't, execute the else
    # Conditions are very simple: of the form <operand><comparison><number>
    def if_command(condition, flag, *_)
      _process_conditional(flag) { evaluate_condition(condition) }
    end

    # .in n
    # Set indent
    def in_command(ind, *_)
      self.indent = self.next_indent = convert_integer(ind, "Indent")
    end

    # .info ARGS
    # Display debugging information (only if .debug mode is on)
    # This is an extension to basic roff
    def info_command(*args)
      info args.join(' ')
    end

    # .ju
    # Turn justification on (i.e. even up right edges)
    # TODO Question -- should this force a flush?
    def ju_command(*_)
      self.justify = true
      self.center = false
    end

    # .li
    # Treat the next line ltterally
    def li_command(*_)
      next_line = get_line
      self.next_line_number += 1
      put_line_paginated(next_line) if next_line
    end

    # .ll n
    # Treat the next line ltterally
    def ll_command(len, *_)
      self.line_length = convert_relative_integer(self.line_length, len, "Line length")
    end

    # .ls N
    # Set line spacing
    def ls_command(n, *_)
      line_count = convert_integer(n, "line spacing")
      force_break
      @line_spacing = line_count
    end

    # .mg
    # <merge line>
    # Sets a mask which is merged with the text on output
    # I.e. the merge mask "shows through", wherever there's
    # a space in the output
    def mg_command(*_)
      next_line = get_line
      exit if next_line == /^\*+$/
      self.merge_string = next_line||''
    end

    # .m1 N
    # Set m1 margin
    def m1_command(n, *_)
      @page_top_margin = convert_integer(n, "margin")
    end

    # .m2 N
    # Set m2 margin
    def m2_command(n, *_)
      @page_bottom_margin = convert_integer(n, "margin")
    end

    # .m3 N
    # Set m3 margin
    def m3_command(n, *_)
      @page_left_margin = convert_integer(n, "margin")
    end

    # .m4 N
    # Set m4 margin
    def m4_command(n, *_)
      @page_right_margin = convert_integer(n, "margin")
    end

    # .ne N
    # Ensure there are at least N lines left in the page
    def ne_command(n, *_)
      end_page if net_page_lines_left < convert_integer(n, "lines needed")
    end

    # .nf
    # Turn off filling (i.e. flowing text)
    def nf_command(*_)
      force_break if self.fill
      self.fill = false
    end

    # .pa N
    # Set page number
    def pa_command(n, *_)
      @page_number = convert_integer(n, "page number")
    end

    # .pc CHARS
    # Set parameter characters (e.g. @ )
    def pc_command(chars='', *_)
      self.parameter_characters, self.parameter_escape = get_escape(chars)
    end

    # .pl N
    # Set page length
    def pl_command(n, *_)
      @page_length = convert_integer(n, "page length")
    end

    # .qc CHARS
    # Set quote characters (e.g. " )
    def qc_command(chars='', *_)
      @quote_characters, @quote_escape = get_escape(chars)
    end

    # .show TYPE NAME
    # Display the value of name. Type may be 'file', 'macro', 'value', 'stack'
    # This is an extension to original ROFF
    def show_command(type, name=nil, *_)
      show_item(type, name)
    end

    # .so FILE  or  .so *BUFFER
    # Source from a file or buffer
    def so_command(file, *_)
      original_file = file
      path = get_file_name(file)
      unless File.exists?(path)
        path += '.txt'
        stop "!File #{original_file} does not exist" unless File.exists?(path)
      end
      self.push context_for_file(path)
    end

    # .sp [N]
    # Insert N blank lines
    def sp_command(n=1, *_)
      line_count = convert_integer(n, "space count")
      force_break
      n.to_i.times { output_line '' }
    end

    # .sq
    # Turn off justification (i.e. flowing text)
    def sq_command(*_)
      force_break if self.justify
      self.justify = false
    end

    # .stop
    # Immediately halt processing
    # This is an extension to original ROFF
    def stop_command(msg=nil, *_)
      stop msg
    end

    # .ta SPECS
    # Set tab stops
    # This is how the stops are specified:
    #   Tab stop specifications are a series of the letters L, C, or R, or numbers (possibly with + or - signs)
    #   If the first entry is numeric, then it's the indentation (as well as a tab stop, possibly)
    #   An n means column n (zero-based)
    #   A +n means n columns after the last tab
    #   A -n means n columns before the next tab
    #   The letter R means right stop; stop is at the first numeric to the right (e.g. R 53 )
    #   The letter L means left stop; stop is at the last numeric to the left (e.g. 42 L )
    #   The letterC means center stop; center between the nearest numerics to the right and left (e.g. 42 C 57 )
    #   So, for example:
    #
    #     .ta 3 R +3 +2 L +8 L C R 51 R 57
    #
    #   Means "set tabs as follows:"
    #     - Indent 3
    #     - First tab stop is a right stop at 6 (3 + 3) -- i.e with its rightmost letter aligned in the seventh column)
    #     - Next stop is a left stop at 8 (i.e. with its leftmost letter aligned in the ninth column)
    #     - Then a left stop at 16
    #     - Then a center stop at 33.5 (because (16+51)/2 = 33.5) -- i.e. with its middle letter aligned halfway
    #       between the 34th and 35th columns (approximately)
    #     - Then a right stop at 51
    #     - Then a right stop at 57
    def ta_command(*tabs)
      stops = decode_tab_stops(*tabs)
      flush if self.fill
      @tab_stops = stops
      @fill = false
      @center = false
      @justify = false
      @tabbed = true
    end

    # .ti n
    # Set temporary indent
    def ti_command(ind, *_)
      self.next_indent = convert_relative_integer(self.next_indent, ind, "Indent")
    end

    # .tr CHARS
    # Set up a character translation
    # e.g.  .tr ABCD  would translate "A"s to "B"s and "C"s to "D"s
    def tr_command(chars, *_)
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
    def ze_command(*args)
      warn translate(args.join(' '))
    end

    # .zz STUFF
    # A comment
    def zz_command(*_)
      # Do nothing
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
        pieces.each do |piece|
          put_piece(piece)
        end
      else
        flush
        self.line_buffer = [line] # Do it this way to force centering, translation, etc.
        flush
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

    def net_page_lines_left
      page_lines_left - @page_top_margin - @page_bottom_margin
    end

    def total_indent
      [next_indent, 0].max 
    end

    def force_break
      flush(justify: false)
    end

    def flush(options={})
      justify = options[:justify]!=false && (options[:justify] || self.justify)
      @temporary_no_justify = false
      unless @line_buffer.size == 0
        info "flush @line_buffer: #{@line_buffer.inspect}, options: #{options.inspect}"
        show_state if @debug
        if self.fill
          info "Filled"
          line = @line_buffer.join
        elsif self.justify
          info "Justify?"
          line = justify_line(@line_buffer)
        elsif self.center
          info "Center?"
          line = center_buffer(@line_buffer)
        elsif self.tabbed
          info "Tabbed"
          line = tabbed_buffer(@line_buffer)
        else
          info "Default?"
          line = @line_buffer.join
        end
        put_line_paginated indent_text(transform(line), total_indent)
        (@line_spacing - 1).times { put_line '' }
      end
      @line_buffer = []
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
        # fname = ".roff_temp_#{f_label}.txt"
        # ::File.open(fname, 'w') {|f| } # Create a null file
        # fname
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
      start_page if @page_line_count == 0
      put_line line
      @page_line_count += @line_spacing
    end

    def start_page
      break_page if @pages_built > 0
      put_headers
      @pages_built += 1
    end

    def end_page
      put_footers
      @page_line_count = 0
      @page_number += 1
    end

    def break_page
      put_line '-'*@line_length
    end

    def put_headers
      @page_headers.each {|header| put_line_parts header }
      (page_top_margin - @page_headers.size).times { put_line '' }
    end

    def put_footers
      (page_bottom_margin - @page_footers.size).times { put_line '' }
      @page_footers.each {|footer| put_line_parts footer }
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