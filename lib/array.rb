#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'pp'
# TODO Move this to a Gem
class Array
  # Take an array of columns and justify each column so that they're all the same width
  # TODO What if columns aren't all the same size?
  # TODO print_table
  # TODO column_append, row_append
  # TODO Move to a subclass: Table
  # TODO Add column heading support
  def justify_columns(options={})
    right_justified_columns = options[:right_justify] || []
    widths = self.map do |column|
      column.map{|entry| entry.to_s.size}.max
    end
    justified = []
    self.each_with_index do |column, column_number|
      if right_justified_columns.include?(column_number)
        justified << column.map{|entry| "%*s" % [widths[column_number], entry] }
      elsif column_number < self.size-1
        justified << column.map{|entry| "%-*s" % [widths[column_number], entry] }
      else
        justified << column
      end
    end
    justified
  end
  
  # Take an array of rows and justify them so each column is all the same width
  def justify_rows(options={})
    self.normalized_transpose.justify_columns(options).transpose
  end
  
  def row_sizes
    self.map{|row| row.size}
  end
  
  # Like transpose, but pads rows out with the specified padding if they're too short
  def normalized_transpose(pad='')
    sizes = row_sizes
    min_size = sizes.min
    max_size = sizes.max
    source = if min_size != max_size # Multiple row sizes
      map{|row| row + [pad]*(max_size - row.size)}
    else
      source = self
    end
    source.transpose
  end
  
  def sum
    self.inject(0) {|s, e| s+e }
  end
end