#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/formatter'

desc "examinations", "List the available examinations for files"
option "long", :aliases=>'-l', :type=>'boolean', :desc=>'Include descriptions'
def examinations
  if options[:long]
    Formatter.open('-', justify: true) do |formatter|
      formatter.titles = %w{Examination Description}
      formatter.format_rows String::Examination.exam_definitions
    end
  else
    puts String::Examination.exams
  end
end