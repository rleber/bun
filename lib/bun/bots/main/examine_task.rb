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
option 'value',   :aliases=>'-v', :type=>'string',  :desc=>"Set the return code based on whether the" +
                                                           " result matches this value"
long_desc <<-EOT
Analyze the contents of a file.

Analyses are available via the --exam parameter. Available analyses include:\x5

#{String::Examination.exam_definition_table.freeze_for_thor}

The command also allows for evaluating arbitrary Ruby expressions.

TODO Explain expression syntax
TODO Explain how --value works

EOT
def examine(file=nil)
  if options[:list]
    puts String::Examination.exam_definition_table
    exit
  end

  stop "!Must provide file name" unless file
  stop "!Cannot handle --exam and --formula" if options[:exam] && options[:formula]
  stop "!Must do either --exam or --formula" if !options[:exam] && !options[:formula]
  stop "!Must specify either --tag or --temp" if options[:formula] && !options[:temp] && !options[:tag]
  
  opts = options.dup # Weird behavior of options here
  asis = opts.delete(:asis)
  options = opts.merge(promote: !asis)
  result = Bun::File.examine(file, options)
  puts result[:result] unless options[:quiet]
  if result[:tag] && !options[:temp] && !File.binary?(file)
    Bun::File::Unpacked.mark(file, {result[:tag]=>result[:result]})
  end
  code = result[:code]
  if options[:value]
    code = options[:value] == result[:result] ? 0 : 1
  end
  exit(code || 0)
rescue Formula::EvaluationError => e
  stop "!Evaluation error: #{e}"
rescue String::Examination::Invalid => e
  warn "!Invalid analysis: #{options[:exam]}" unless options[:quiet]
  exit(99)
end
