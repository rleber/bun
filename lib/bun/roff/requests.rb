#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class Roff
    # .af NAME FORMAT
    # Assign format to variable
    # Formats are as a mask, e.g. '001' would be a three character format, with leading zeroes
    def af_request(name, format, *_)
      defn = get_definition(name)
      err "!Variable #{name.text} not defined" unless defn
      err "!#{name.text} is not a numeric register" unless defn[:data_type] == :number
      defn[:format] = format.text
    end

    # .an NAME EXPRESSION
    # Set a value. Expression may be:
    #    n (numeric)  Set the named value to this value
    #    +n           Add n to the named value
    #    -n           Subtract n from the named value
    def an_request(name, *expression)
      defn = get_definition(name)
      defn = define_register(name, 0) unless defn
      if expression.size==0
        defn.value = 0
      else
        defn.value = convert_expression(defn.value, expression, "expression")
      end
    end

    # .at NAME
    # ...
    # .en NAME
    # Define a register named NAME.
    def at_request(name, *_)
      tag = name
      name = $1 if name=~/^\((.*)\)$/
      defn = define_register name
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

    # .bp
    # Page break
    def bp_request(*args)
      force_break
      finish_page
    end

    # .br
    # Line break
    def br_request(*args)
      force_break
    end

    # .cc
    # Set control character
    def cc_request(c,*_)
      self.control_character = c.value
    end

    # .ce n
    # Center the next n lines
    def ce_request(n=nil, *_)
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
    def cl_request(fn, *_)
      get_file fn
      # No other action required
    end

    # .debug [SETTING]
    # Set debug mode on or off
    # This is an extension to the original ROFF
    def debug_request(flag='on', *_)
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
    def dn_request(fn, flag, *_)
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

    # .ef '...'...'...'
    # Set even page footer
    # In the example above, "'" could be any character
    def ef_request(*args)
      n=0
      spec = line_part_spec
      @page_footers[0][n] = spec
    end

    # .eh '...'...'...'
    # Set even page header
    # In the example above, "'" could be any character
    def eh_request(*args)
      n=0
      spec = line_part_spec
      @page_headers[0][n] = spec
    end

    # .el tag
    # Else clause of if/else conditional (e.g. .if, or .id). Should never occur by itself
    def el_request(tag, *_)
      log "Unmatched .el found:" + stack_trace.first
    end

    # .en tag
    # End of block command (e.g. .if). Should never occur by itself
    def en_request(tag, *_)
      log "Unmatched .en found:" + stack_trace.first
    end

    # .ep
    # Start the next even page
    def ep_request(*_)
      force_break
      end_page
      until @page_number.odd? # Because if we stop on an odd page, the next one will be even
        break_page
      end
    end

    # .fa n name
    # Attach a file; n is the file number. File names starting with '*' are temporary files
    def fa_request(fn, name, *_)
      ix = convert_integer(fn, "!File number")
      @files[ix] = {name: name.sub(/^\*/,''), path: get_file_name(name), number: ix}
    end

    # .fi
    # Turn filling on (i.e. flow text, word by word)
    def fi_request(*_)
      force_break
      self.fill = true
    end

    # .fo '...'...'...'
    # Set page footer
    # In the example above, "'" could be any character
    def fo_request(*args)
      n=0
      spec = line_part_spec
      @page_footers[0][n] = @page_footers[1][n] = spec
    end

    # .hc CHAR
    # Set hyphenation marker. Roff will attempt to hyphenate words here
    def hc_request(char, *_)
      @hyphenation_character = char.text
    end

    # .he '...'...'...'
    # Set page heading
    # In the example above, "'" could be any character
    def he_request(*args)
      n=0
      spec = line_part_spec
      @page_headers[0][n] = @page_headers[1][n] = spec
    end

    # .hy MODE
    # Set hyphenation mode: 0 = no hyphenation, 1=explicit 2=minimal, 3=full
    # Note: we ignore modes 1 and 2 and treat them the same as 3
    def hy_request(mode, *_)
      self.hyphenation_mode = convert_integer(mode, "hyphenation mode")
      err "!#{mode} must be 0-3" unless (0..3).include?(self.hyphenation_mode)
    end

    # .ic CHARS
    # Set insertion characters (e.g. ^^ )
    def ic_request(chars='', *_)
      @insert_character, @insert_escape = convert_string(chars, "insertion character")
    end

    # .id NAME
    # ...
    # .el NAME (optional)
    # ...
    # .en NAME
    # If name is defined, execute the first part. If it isn't, execute the else
    def id_request(name, flag, *_)
      _process_conditional(flag) { @definitions[name] }
    end

    # .if CONDITION TAG
    # ...
    # .el TAG (optional)
    # ...
    # .en TAG
    # If the condition is true, execute the first part. If it isn't, execute the else
    # Conditions are very simple: of the form <operand><comparison><number>
    def if_request(condition, flag, *_)
      _process_conditional(flag) { evaluate_condition(condition) }
    end

    # .in n
    # Set indent
    def in_request(ind, *_)
      self.indent = self.next_indent = convert_integer(ind, "Indent")
    end

    # .info ARGS
    # Display debugging information (only if .debug mode is on)
    # This is an extension to basic roff
    def info_request(*args)
      info args.join(' ')
    end

    # .ju
    # Turn justification on (i.e. even up right edges)
    # TODO Question -- should this force a flush?
    def ju_request(*_)
      force_break
      self.justify = true
      self.center = false
    end

    # .li
    # Treat the next line ltterally
    def li_request(n=nil,*_)
      ct = n ? convert_integer(n, "line count") : 1
      force_break
      ct.times do 
        next_line = get_line
        put_line_paginated(next_line) if next_line
      end
    end

    # .ll n
    # Treat the next line ltterally
    def ll_request(*args)
      self.line_length = convert_expression(self.line_length, args, "Line length")
    end

    # .ls N
    # Set line spacing
    def ls_request(*args)
      line_count = convert_expression(@line_spacing, args, "line spacing")
      force_break
      @line_spacing = line_count
    end

    # .lv N
    # Leave a block of N blank lines
    def lv_request(n, *_)
      ct = convert_integer(n, "lines")
      if net_page_lines_left_at_spacing < ct
        set_trap(0) { ct.times { put_line_paginated '' } }
      else
        sp_request(n)
      end
    end

    # .mg
    # <merge line>
    # Sets a mask which is merged with the text on output
    # I.e. the merge mask "shows through", wherever there's
    # a space in the output
    def mg_request(*_)
      next_line = get_line
      exit if next_line == /^\*+$/
      self.merge_string = next_line||''
    end

    # .m1 N
    # Set m1 margin
    def m1_request(n, *_)
      @page_top_margin = convert_integer(n, "margin")
    end

    # .m2 N
    # Set m2 margin
    def m2_request(n, *_)
      @page_header_margin = convert_integer(n, "margin")
    end

    # .m3 N
    # Set m3 margin
    def m3_request(n, *_)
      @page_footer_margin = convert_integer(n, "margin")
    end

    # .m4 N
    # Set m4 margin
    def m4_request(n, *_)
      @page_bottom_margin = convert_integer(n, "margin")
    end

    # .ne N
    # Ensure there are at least N lines left in the page
    def ne_request(n, *_)
      finish_page if net_page_lines_left_at_spacing < convert_integer(n, "lines needed")
    end

    # .nf
    # Turn off filling (i.e. flowing text)
    def nf_request(*_)
      force_break if self.fill
      self.fill = false
    end

    # .nj
    # Turn off justification
    def nj_request(*_)
      self.justify = false
    end

    # .of '...'...'...'
    # Set odd page footer
    # In the example above, "'" could be any character
    def of_request(*args)
      n=0
      spec = line_part_spec
      @page_footers[1][n] = spec
    end

    # .oh '...'...'...'
    # Set odd page header
    # In the example above, "'" could be any character
    def oh_request(*args)
      n=0
      spec = line_part_spec
      @page_headers[1][n] = spec
    end

    # .op
    # Start the next odd page
    def op_request(*_)
      force_break
      end_page
      until @page_number.even? # Because if we stop on an even page, the next one will be odd
        break_page
      end
    end


    # .pa N
    # Set page number
    def pa_request(*args)
      bp_request
      @page_number = convert_expression(@page_number, args, "page number") - 1 # Becaue it will be incremented
    end

    # TODO Fix this syntax -- it isn't right (also qc, etc.)
    # .pc CHARS
    # Set parameter characters (e.g. @ )
    def pc_request(chars='', *_)
      self.parameter_character, self.parameter_escape = convert_string(chars, "parameter character")
    end

    # .pl N
    # Set page length
    def pl_request(n, *_)
      force_break
      @page_length = convert_integer(n, "page length")
    end

    # .qc CHARS
    # Set quote characters (e.g. " )
    def qc_request(chars='', *_)
      @quote_character, @quote_escape = convert_string(chars, "quotation character")
    end

    # .show TYPE NAME
    # Display the value of name. Type may be 'file', 'register', 'value', 'stack'
    # This is an extension to original ROFF
    def show_request(type, name=nil, *_)
      show_item(type, name)
    end

    # .so FILE  or  .so *BUFFER
    # Source from a file or buffer
    def so_request(file, *_)
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
    def sp_request(n=1, *_)
      line_count = convert_integer(n, "space count")
      force_break
      line_count.times do 
        break if @page_line_count == 0
        put_line_paginated ''
      end
    end

    # .sq
    # Turn off justification (i.e. flowing text)
    def sq_request(*_)
      force_break if self.justify
      self.justify = false
    end

    # .stop
    # Immediately halt processing
    # This is an extension to original ROFF
    def stop_request(msg=nil, *_)
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
    def ta_request(*tabs)
      stops = decode_tab_stops(*tabs)
      @tab_stops = stops
      @fill = false
      @center = false
      @justify = false
      @tabbed = true
    end

    # .ti n
    # Set temporary indent
    def ti_request(*args)
      self.next_indent = convert_expression(self.next_indent, args, "Indent")
    end

    # .tr CHARS
    # Set up a character translation
    # e.g.  .tr ABCD  would translate "A"s to "B"s and "C"s to "D"s
    def tr_request(chars, *_)
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
    def ze_request(*args)
      warn translate(args.join(' '))
    end

    # .zz STUFF
    # A comment
    def zz_request(*_)
      # Do nothing
    end
  end
end