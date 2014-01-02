#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "examine [FILE]", "Analyze the contents of a file"
option 'asis',    :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to decode file"
option 'case',    :aliases=>'-c', :type=>'boolean', :desc=>"Case insensitive"
option 'exam',    :aliases=>'-e', :type=>'string',  :desc=>"What test? See bun help check for options"
option 'formula', :aliases=>'-f', :type=>'string',  :desc=>"Evaluate a Ruby formula -- see help"
option 'list',    :aliases=>'-l', :type=>'boolean', :desc=>"List the defined examinations"
option 'min',     :aliases=>'-m', :type=>'numeric', :desc=>"For counting examinations: minimum count"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
option 'tag',     :aliases=>'-T', :type=>'string',  :desc=>"Override the standard mark name"
option 'temp',    :aliases=>'-t', :type=>'boolean', :desc=>"Don't mark the test in the file"
long_desc <<-EOT
Analyze the contents of a file.

Analyses are available via the --exam parameter. Available analyses include:\x5

#{String::Examination.exam_definition_table.freeze_for_thor}

The command also allows for evaluating arbitrary Ruby expressions.

EOT
def examine(file=nil)
  if options[:list]
    puts String::Examination.exam_definition_table
    exit
  end
  stop "!Must provide file name" unless file
  stop "!Cannot handle --exam and --formula" if options[:exam] && options[:formula]
  if options[:exam]
    examination = Bun::File.examination(file, options[:exam], promote: !options[:asis])
    # TODO Change this to range
    examination.minimum = options[:min] if examination.respond_to?(:minimum)
    examination.case_insensitive = options[:case] if examination.respond_to?(:case_insensitive)
    result = examination.to_s
    code = examination.code
    tag = "exam:#{options[:exam]}"
  elsif options[:formula]
    # TODO allow other parameters to the formula, from the command line
    formula = Bun::File.formula(file, options[:formula], promote: !options[:asis])
    result = formula.to_s
    tag = "formula:#{options[:formula]}"
  else
    stop "!Must provide either --exam or --formula"
  end
  puts result unless options[:quiet]
  tag = options[:tag] || tag
  unless options[:temp] || File.binary?(file)
    Bun::File::Unpacked.mark(file, {tag=>result})
  end
  exit(code || 0)
rescue String::Examination::Invalid => e
  warn "!Invalid analysis: #{options[:exam]}" unless options[:quiet]
  exit(99)
end
