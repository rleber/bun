#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "examine [FILE]", "Analyze the contents of a file"
option 'asis',  :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to decode file"
option 'case',  :aliases=>'-c', :type=>'boolean', :desc=>"Case insensitive"
option 'exam',  :aliases=>'-e', :type=>'string',  :desc=>"What test? See bun help check for options",
                :default=>'clean'
option 'list',  :aliases=>'-l', :type=>'boolean', :desc=>"List the defined examinations"
option 'min',   :aliases=>'-m', :type=>'numeric', :desc=>"For counting examinations: minimum count"
option 'quiet', :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
option 'tag',   :aliases=>'-T', :type=>'string',  :desc=>"Override the standard mark name"
option 'temp',  :aliases=>'-t', :type=>'boolean', :desc=>"Don't mark the test in the file"
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
  examination = Bun::File.examination(file, options[:exam], promote: !options[:asis])
  # TODO Change this to range
  examination.minimum = options[:min] if examination.respond_to?(:minimum)
  examination.case_insensitive = options[:case] if examination.respond_to?(:case_insensitive)
  test_result = examination.to_s
  puts test_result unless options[:quiet]
  tag = options[:tag] || "exam:#{options[:exam]}"
  unless options[:temp] || File.binary?(file)
    Bun::File::Unpacked.mark(file, {tag=>test_result})
  end
  exit(examination.code || 0)
rescue String::Examination::Invalid => e
  warn "!Invalid analysis: #{options[:exam]}" unless options[:quiet]
  exit(99)
end
