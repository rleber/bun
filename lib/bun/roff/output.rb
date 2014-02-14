#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class Roff
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
      if [:whitespace, :end_of_line].include?(piece.type)
        return if @line_buffer.size==0 # Don't start lines with spaces
        if [:whitespace, :end_of_line].include?(@line_buffer.last.type) # Not necessary to add to spacing
          @line_buffer[-1] = piece
          return
        end
      end
      if piece_type == :end_of_line
        ws = ParsedNode.create(:whitespace, text: ' ', interval: piece.interval)
        @line_buffer.pop
        if @line_buffer.size>0 && LINE_ENDINGS.include?(@line_buffer[-1].output_text)
          @line_buffer.push ws
        end
        @line_buffer.push ws
      else
        @line_buffer << [piece]
      end
      line_buffer_size = @line_buffer.map {|piece| piece.output_text }.join.size
      if line_buffer_size > net_line_length 
        return unless [:whitespace, :end_of_line].include?(piece.type) # Only break at whitespace
        output_buffer_head
      end
    end

    def flush(options={})
      output_buffer_head
      flush_remainder(options)
    end

    # Output as much of the buffer as you can
    # Buffer should be longer than a line at this point; break it where you can
    # If there's an exceptionally long word in there, this may take more than one line
    def output_buffer_head
      # Drop trailing hyphenation
      while @line_buffer.size > 0
        break unless @line_buffer.last.type == :whitespace
        @line_buffer.pop
      end
      line_size = 0
      parts = @line_buffer.group_by do |part|
        line_size += part.output_text
        line_size <= net_line_length
      end
      fits = parts[true]
      overflows = parts[false]
      if overflows.size > 0
        if self.hyphenation_mode>0 && overflows[0].type == :word # Attempt to hyphenate
          atom = overflows[0].output_text
          next_buffer = fits + [overflows[0]]
          next_buffer_text = next_buffer.map {|p| p.output_text }
          next_buffer_size = next_buffer_text.map {|p| p.size }.sum
          minimum_suffix_size = next_buffer_size - net_line_length + HYPHEN.size
          hyphenation_suffix = self.hyphenator.sentence_suffix(next_buffer_text, minimum_suffix_size)
          if hyphenation_suffix == '' || hyphenation_suffix == atom
            next_buffer = overflows
          else
            fits << (atom[0...-(hyphenation_suffix.size)]+HYPHEN)
            hyphenation_suffix_interval = overflows[0].interval.dup
            hyphenation_suffix_interval.begin += (atom.size - hyphenation_suffix.size)
            next_buffer = [ParseNode.create(:word, text: hyphenation_suffix, interval: hyphenation_suffix_interval)]
          end
        end
      end

      if piece.type == :whitespace
        next_buffer = []
      elsif self.hyphenation_mode==0 || piece.type != :word
        next_buffer = [atom]
      # TODO Check for hyphenation character
      else # Attempt to hyphenate
        minimum_suffix_size = next_buffer_size - net_line_length + HYPHEN.size
        hyphenation_suffix = self.hyphenator.sentence_suffix(next_buffer, minimum_suffix_size)
        if hyphenation_suffix == '' || hyphenation_suffix == atom
          next_buffer = [atom]
        else
          @line_buffer << (atom[0...-(hyphenation_suffix.size)]+HYPHEN)
          next_buffer = [hyphenation_suffix]
        end
      end
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

    def flush_remainder(options={})
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
  end
end