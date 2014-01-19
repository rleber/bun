#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Format output in multiple ways

require 'csv'

module Bun
  class Formatter
    VALID_FORMATS = [:text, :csv]
    DEFAULT_FORMAT = :text

    class << self
      def valid_formats
        VALID_FORMATS
      end

      def valid_format?(format)
        valid_formats.include?(format.to_sym)
      end

      def open(file_name, options={})
        formatter = new(file_name, options)
        yield(formatter)
      ensure
        formatter.close
      end
    end

    attr_reader :file_name, :file, :format, :justify, :shell, :buffer, :count
    attr_accessor :right_justified_columns

    def initialize(file_name, options={})
      @file_name = file_name
      @file = file_name == '-' ? $stdout : File.open(file_name, 'w')
      @format = options[:format] || DEFAULT_FORMAT
      @justify = options[:justify]
      @right_justified_columns = options[:right_justified_columns]
      @buffer = []
      shell = Shell.new
      @count = 0
      @titles = nil
    end

    def close
      finish
      @buffer.each {|row| write_row(row)}
      @file.close unless file_name == '-'
    end

    def titles=(row)
      raise "Can't reset titles" if @titles
      raise "Have already output rows; can't set titles now" if !justify && count>0
      @titles = row
      if justify
        @buffer.unshift(row)
      else
        write_row row
      end
    end

    def <<(row)
      start if @count==0 # Lazy invocation of start
      @count += 1
      if justify
        @buffer << row
      else
        write_row row
      end
      self # For chaining
    end

    def format_rows(rows)
      rows.each {|row| self<<row }
    end

    def write_row(row)
      self.send("write_#{@format}", row)
    end

    def start
      self.send("start_#{format}") if self.respond_to?("start_#{format}") # Start hook
    end

    def finish
      if justify
        @buffer = @buffer.justify_rows(right_justify: right_justified_columns)
      end
      self.send("finish_#{format}") if self.respond_to?("finish_#{format}") # Finish hook
    end

    def write_text(row)
      write row.join('  ')
    end

    def write_csv(row)
      write row.to_csv
    end

    def write(text)
      file.puts text
    end
  end
end
