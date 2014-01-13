#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "find FILES", "Find and print all the files matching certain criteria"
option 'asis',    :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to decode files"
option 'case',    :aliases=>'-c', :type=>'boolean', :desc=>"Case insensitive"
option 'exam',    :aliases=>'-e', :type=>'string',  :desc=>"What test? See bun help check for options"
option 'formula', :aliases=>'-f', :type=>'string',  :desc=>"Evaluate a Ruby formula -- see help"
option 'list',    :aliases=>'-l', :type=>'boolean', :desc=>"List the defined examinations"
option 'match',   :aliases=>'-m', :type=>'string',  :desc=>"Matches this regular expression (Ruby format)"
option 'min',     :aliases=>'-M', :type=>'numeric', :desc=>"For counting examinations: minimum count"
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
  check_for_unknown_options(*files)
  if options[:list]
    puts String::Examination.exam_definition_table
    exit
  end

  option_count = [:exam, :formula, :match].inject(0) {|sum, option| sum += 1 if options[option]; sum }
  stop "!Cannot have more than one of --exam, --formula and --match" if option_count > 1
  stop "!Must do one of --exam, --formula or --match" if option_count == 0
  stop "!Must specify --value with --formula" if options[:formula] && !options[:value]
  
  opts = options.dup # Weird behavior of options here
  asis = opts.delete(:asis)
  options = opts.merge(promote: !asis)

  Archive.examine_select(files, options) do |result| 
    puts result[:file]
  end
end
