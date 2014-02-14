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
        # debug "self.line: #{self.line.inspect}"
        self.parsed_line = parse(self.line)
        # debug "self.parsed_line: #{self.parsed_line.inspect}"
        self.expanded_lines = expand(self.parsed_line)
        # debug "self.expanded_lines: #{self.expanded_lines.inspect}"
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
  end
end