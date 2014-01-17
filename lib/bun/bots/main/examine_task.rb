#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "examine [FILE]", "Analyze the contents of a file"
option 'asis',    :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to decode file"
option 'case',    :aliases=>'-c', :type=>'boolean', :desc=>"Case insensitive"
option 'exam',    :aliases=>'-e', :type=>'string',  :desc=>"What test? See bun help check for options"
option 'field',   :aliases=>'-F', :type=>'string',  :desc=>"Return the value in a field"
option 'formula', :aliases=>'-f', :type=>'string',  :desc=>"Evaluate a Ruby formula -- see help"
option 'usage',   :aliases=>'-l', :type=>'boolean', :desc=>"List usage information"
option 'match',   :aliases=>'-m', :type=>'string',  :desc=>"Matches this regular expression (Ruby format)"
option 'min',     :aliases=>'-M', :type=>'numeric', :desc=>"For counting examinations: minimum count"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
option 'tag',     :aliases=>'-T', :type=>'string',  :desc=>"Override the standard mark name"
option 'temp',    :aliases=>'-t', :type=>'boolean', :desc=>"Don't mark the test in the file"
option 'text',    :aliases=>'-x', :type=>'boolean', :desc=>"Based on the text in the file"
option 'value',   :aliases=>'-v', :type=>'string',  :desc=>"Set the return code based on whether the" +
                                                           " result matches this value"
long_desc <<-EOT
Query the contents or characteristics of a file.

Analyses are available via the --query parameter.

#{String::Examination.usage.freeze_for_thor}

EOT
def examine(file=nil)
  check_for_unknown_options(file)
  if options[:usage]
    puts String::Examination.usage
    exit
  end

  stop "!Must provide file name" unless file
  option_count = [:exam, :field, :formula, :match, :text] \
      .inject(0) {|sum, option| sum += 1 if options[option]; sum }
  stop "!Cannot have more than one of --exam, --field, --formula, --match, and --text" if option_count > 1
  stop "!Must do one of --exam, --field, --formula, --match, or --text" if option_count == 0
  stop "!Must specify either --tag or --temp" if options[:formula] && !options[:temp] && !options[:tag]
  
  opts = options.dup # Weird behavior of options here
  asis = opts.delete(:asis)
  options = opts.merge(promote: !asis)
  result = Bun::File.examination(file, options)
  if options[:match]
    puts result[:result] ? 'match' : 'no_match' unless options[:quiet]
  else
    puts result[:result].to_s unless options[:quiet]
  end
  if result[:tag] && !options[:match] && !options[:field] && !options[:temp] && !File.binary?(file)
    Bun::File::Unpacked.mark(file, {result[:tag]=>result[:result]}.inspect)
  end
  code = result[:code]
  if options[:value]
    code = options[:value] == result[:result] ? 0 : 1
  end
  exit(code || 0)
rescue Formula::EvaluationError => e
  stop "!Evaluation error: #{e}"
rescue String::Examination::Invalid => e
  warn "!#{options[:exam]} is an invalid analysis: #{e}" unless options[:quiet]
  exit(99)
end
