#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/formatter'

desc "examinations PATTERN", "List the available examinations for files"
option "long",    :aliases=>'-l', :type=>'boolean', :desc=>'Include descriptions'
option "options", :aliases=>'-o', :type=>'boolean', :desc=>'Show options usage information for examinations'
def examinations(pattern='.*')
  regex = %r{#{pattern}}i
  exams = String::Examination.exams.select {|name| name =~ regex }
  long = options[:long] || options[:options]
  rows = exams.map do |exam|
    long ? String::Examination.exam_definitions.find {|name, defn| name == exam } : [exam]
  end
  Formatter.open("-", justify: true) do |usage_formatter|
    if options[:options]
      usage_formatter.titles = %w{Examination/Options Description}
    elsif long
      usage_formatter.titles = %w{Examination Description}
    end
    rows.each do |row|
      usage_formatter << row
      next if !options[:options]
      exam_class = String::Examination.exam_class(row[0])
      exam_class.option_definitions.each do |usage_defn|
        usage_formatter << ["  "+usage_defn[:name], "  "+usage_defn[:desc]]
      end
    end
  end
end