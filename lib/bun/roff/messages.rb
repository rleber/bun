#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class Roff
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