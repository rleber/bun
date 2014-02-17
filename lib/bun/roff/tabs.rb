#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class Roff
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
  end
end