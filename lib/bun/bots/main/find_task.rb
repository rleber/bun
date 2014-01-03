#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "find FILES", "Find and print all the files matching certain criteria"
option 'asis',    :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to decode files"
option 'case',    :aliases=>'-c', :type=>'boolean', :desc=>"Case insensitive"
option 'exam',    :aliases=>'-e', :type=>'string',  :desc=>"What test? See bun help check for options"
option 'formula', :aliases=>'-f', :type=>'string',  :desc=>"Evaluate a Ruby formula -- see help"
option 'list',    :aliases=>'-l', :type=>'boolean', :desc=>"List the defined examinations"
option 'min',     :aliases=>'-m', :type=>'numeric', :desc=>"For counting examinations: minimum count"
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
def find(*files)
  if options[:list]
    puts String::Examination.exam_definition_table
    exit
  end

  stop "!Cannot handle --exam and --formula" if options[:exam] && options[:formula]
  stop "!Must do either --exam or --formula" if !options[:exam] && !options[:formula]
  stop "!Must specify --value with --formula" if options[:formula] && !options[:value]
  
  opts = options.dup # Weird behavior of options here
  asis = opts.delete(:asis)
  options = opts.merge(promote: !asis)

  Archive.examine_select(files, options) do |result| 
    puts result[:file]
  end
end
