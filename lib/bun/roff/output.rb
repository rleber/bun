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
        self.line_buffer = line # Do it this way to force centering, translation, etc.
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
      if piece.type == :end_of_line
        ws = ParsedNode.create(:whitespace, text: ' ', interval: piece.interval)
        if @line_buffer.size>0 && LINE_ENDINGS.include?(@line_buffer[-1].output_text)
          @line_buffer.push ws
        end
        @line_buffer.push ws
      else
        @line_buffer << piece
      end
      line_buffer_size = @line_buffer.map {|piece| piece.output_text }.join.size
      if line_buffer_size > net_line_length 
        return unless [:whitespace, :end_of_line].include?(piece.type) # Only break at whitespace
        fill_buffer
      end
    end

    def flush(options={})
      fill_buffer(options) if self.fill
      flush_buffer(@line_buffer, options)
      @line_buffer = []
    end

    # Output as much of the buffer as you can
    # Buffer should be longer than a line at this point; break it where you can
    # If there's an exceptionally long word in there, this may take more than one line
    def fill_buffer(options={})
      next_line = []
      unplaced_tokens = []
      # Repeat line-by-line until the whole buffer is placed (a tail end may remain)
      loop do
        # Drop leading whitespace in a line
        while @line_buffer.size > 0
          break unless [:whitespace, :end_of_line].include?(@line_buffer[0].type)
          @line_buffer.shift
        end
        break if @line_buffer.size == 0
        line_size = 0
        unplaced_tokens_size = 0
        last_interval_end = nil
        tokens_placed = false
        # Place tokens in unplaced_tokens; move them to line when they fit, breaking only at whitespace
        loop do
          next_token = @line_buffer.shift
          next_output_text = next_token.output_text
          line_size += next_output_text.size
          unplaced_tokens_size += next_output_text.size
          unplaced_tokens << next_token
          if [:whitespace, :end_of_line].include?(next_token.type) 
            if line_size - next_output_text.size <= net_line_length
              next_line += unplaced_tokens
              unplaced_tokens = []
              unplaced_tokens_size = 0
              tokens_placed = true
            else
              break
            end
          end
          last_interval_end = next_token.interval.end
          break if @line_buffer.size == 0
        end
        # At this point: 
        # - @line_buffer has had several (possibly all) tokens shifted out of it,
        # - next_line has some (possibly zero) tokens in it, all of which will fit in the next line
        # - unplaced_tokens contains a set of tokens (possibly none) waiting to be placed; they may overflow the line
        # - line_size contains the combined lengths of the tokens in next_line and unplaced_tokens
        # - unplaced_tokens_size contains the combined length of the tokens in unplaced_tokens
        break if line_size < net_line_length
        hyphenated_tokens = unplaced_tokens.flat_map {|token| hyphenate(token)}
        unplaced_tokens = []
        unplaced_tokens_size = 0
        target_line_length = net_line_length - HYPHEN.size
        hyphenated_syllable_count = 0
        while hyphenated_tokens.size > 0
          token = hyphenated_tokens.last # Go in reverse
          break if token.type==:word && hyphenated_syllable_count > 0 && line_size <= target_line_length
          if token.output_text == "-" && hyphenated_syllable_count > 0 && line_size <= target_line_length
            hyphenated_tokens.pop
            break
          end
          unplaced_tokens.unshift(hyphenated_tokens.pop)
          token_size = token.output_text.size
          unplaced_tokens_size += token_size
          line_size -= token_size
          hyphenated_syllable_count = token.type == :word ? hyphenated_syllable_count + 1 : 0
        end
        if hyphenated_tokens.size > 0
          next_line += hyphenated_tokens
          next_line << ParsedNode.create(:other, text: HYPHEN, interval: Range.new(last_interval_end, last_interval_end, true)) \
            if hyphenated_syllable_count > 0
        else
          if !tokens_placed && unplaced_tokens.size > 0 # Didn't place anything
            if unplaced_tokens.first.output_text.size > net_line_length
              long_token = unplaced_tokens.first
              target_line_length = net_line_length
              target_line_length -= HYPHEN.size if long_token.type==:word
              next_line << ParsedNode.create(
                             long_token.type,
                             text: long_token.output_text[0, target_line_length],
                             interval: Range.new(long_token.interval.begin, long_token.interval.begin+target_line_length, true)
                           )
              next_line << ParsedNode.create(
                             :other,
                             text: HYPHEN,
                             interval: Range.new(long_token.interval.begin+target_line_length, long_token.interval.begin+target_line_length, true)
                           ) if long_token.type == :word
              unplaced_tokens[0] = ParsedNode.create(
                                     long_token.type,
                                     text: long_token.output_text[target_line_length..-1],
                                     interval: Range.new(long_token.interval.begin+target_line_length, long_token.interval.end, true)
                                   )
            else
              while unplaced_tokens.size > 0 do
                token = unplaced_tokens.first
                token_size = token.output_text.size
                break if line_size + token_size > net_line_length
                next_line << unplaced_tokens.shift
                line_size += token_size
              end
            end
          end
        end
        if unplaced_tokens.size==0 && @line_buffer.size==0
          flush_buffer(next_line, options)
        else
          flush_buffer(next_line)
        end
        next_line = unplaced_tokens
        unplaced_tokens = []
      end
      @line_buffer = next_line + unplaced_tokens
    end

    def hyphenate(word)
      return [word] if word.type != :word
      return [word] if self.hyphenation_mode ==0 && word.output_text.size <= net_line_length
      start = word.interval.begin
      if @hyphenation_character.to_s!="" && (s=word.output_text.split(@hyphenation_character)).size>1
        parts = s
      else
        parts = self.hyphenator.hyphenate(word.output_text)
      end 
      parts.map do |part|
        part_range = Range.new(start, start+part.size, true)
        start += part.size
        ParsedNode.create(:word, text: part, interval: part_range)
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

    def flush_buffer(buffer, options={})
      justify = options[:justify]!=false && (options[:justify] || self.justify)
      unless buffer.size == 0
        buffer = buffer.map {|token| token.output_text }
        show_state if @debug
        if self.fill
          if justify
            line = justify_line(buffer)
          else
            trim_buffer buffer
            line = buffer.join
          end
        elsif self.center
          trim_buffer buffer
          line = center_buffer(buffer)
        elsif self.tabbed
          line = tabbed_buffer(buffer)
        else
          line = buffer.join
        end
        buffer = []
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