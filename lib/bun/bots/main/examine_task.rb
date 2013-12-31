#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO add --mark option
desc "examine [FILE]", "Analyze the contents of a file"
option 'list',  :aliases=>'-l', :type=>'boolean', :desc=>"List the defined examinations"
option 'mark',  :aliases=>'-m', :type=>'boolean', :desc=>"Mark the test in the file"
option 'test',  :aliases=>'-t', :type=>'string',  :desc=>"What test? See bun help check for options",
                :default=>'clean'
option 'quiet', :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
long_desc <<-EOT
Analyze the contents of a file.

Available analyses include:\x5

#{String::Examination.exam_definition_table.freeze_for_thor}

EOT
def examine(file=nil)
  if options[:list]
    puts String::Examination.exam_definition_table
    exit
  end
  stop "!Must provide file name" unless file
  examination = Bun::File.examination(file, options[:test])
  test_result = examination.to_s
  puts test_result unless options[:quiet]
  Bun::File::Unpacked.mark(file, {options[:test]=>test_result}) if options[:mark]
  exit(examination.code || 0)
rescue String::Examination::Invalid => e
  warn "!Invalid analysis: #{options[:test]}" unless options[:quiet]
  exit(99)
end
