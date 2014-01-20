#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "same [OPTIONS] EXAMINATIONS... FILES...", "Group files which match on a certain criterion"
option 'asis',    :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to decode files"
option 'case',    :aliases=>'-c', :type=>'boolean', :desc=>"Case insensitive"
option 'format',  :aliases=>'-F', :type=>'string',  :desc=>"Use other formats", :default=>'text'
option 'inspect', :aliases=>'-I', :type=>'boolean', :desc=>"Just echo back the value of --exam as received"
option 'justify', :aliases=>'-j', :type=>'boolean', :desc=>"Justify the rows"
option 'min',     :aliases=>'-m', :type=>'numeric', :desc=>"For counting examinations: minimum count"
option 'text',    :aliases=>'-x', :type=>'boolean', :desc=>"Based on the text in the file"
option 'usage',   :aliases=>'-u', :type=>'boolean', :desc=>"List usage information"
option 'value',   :aliases=>'-v', :type=>'string',  :desc=>"Set the return code based on whether the" +
                                                           " result matches this value"
long_desc <<-EOT
Group files which match on certain criteria.

Analyses are available via the --exam parameter. Available analyses include:\x5

#{String::Examination.exam_definition_table.freeze_for_thor}

The command also allows for evaluating arbitrary Ruby expressions.

TODO Explain expression syntax
TODO Explain how --value works

EOT
def same(*args)
  # Check for separator ('--in') between exams and files
  exams, files = split_arguments_at_separator('--in', *args, assumed_before: 1)
  check_for_unknown_options(*exams, *files)

  if options[:usage]
    puts String::Examination.usage
    exit
  end
  
  if options[:inspect]
    puts exams
    exit
  end
  
  case exams.size
  when 0
    stop "!First argument should be an examination expression"
  when 1
    exam = exams.first 
  else
    exam = '[' + exams.join(',') + ']'
  end
  
  stop "!Must provide at least one file " unless files.size > 0


  opts = options.dup # Weird behavior of options here
  asis = opts.delete(:asis)
  options = opts.merge(promote: !asis)

  # TODO DRY this up (same logic in map_task)
  # TODO Allow shard specifiers
  dups = Archive.duplicates(exam, files, options)
  last_key = nil
  dups.keys.sort.each do |key|
    puts "" if last_key
    dups[key].each {|dup| puts ([key] + [dup]).flatten.join('  ')}
    last_key = key
  end
end
