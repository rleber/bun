#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "examine [OPTIONS] EXAMINATION FILE...", "Analyze the contents of files"
option 'asis',    :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to decode file"
# TODO Needs some explanation
option 'case',    :aliases=>'-c', :type=>'boolean', :desc=>"Case insensitive"
option 'inspect', :aliases=>'-i', :type=>'boolean', :desc=>"Just echo back the value of --exam as received"
# TODO Better syntax for this?
option 'min',     :aliases=>'-M', :type=>'numeric', :desc=>"For counting examinations: minimum count"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
option 'save',    :aliases=>'-s', :type=>'string',  :desc=>"Save the result under this name as a mark in the file"
option 'usage',   :aliases=>'-u', :type=>'boolean', :desc=>"List usage information"
# TODO Is this still necessary?
option 'value',   :aliases=>'-v', :type=>'string',  :desc=>"Set the return code based on whether the" +
                                                           " result matches this value"
long_desc <<-EOT
Examine the contents or characteristics of files.

Many analyses are available via the EXAMINATION parameter. See --usage for more detail.
EOT
def examine(*args)
  check_for_unknown_options(*args)
  if options[:usage]
    puts String::Examination.usage
    exit
  end

  stop "!First argument should be an examination expression" unless args.size > 1
  exam = args.shift
  
  if options[:inspect]
    puts exam
    exit
  end

  stop "!Must provide at least one file " unless args.size > 0

  opts = options.dup # Weird behavior of options here
  asis = opts.delete(:asis)
  options = opts.merge(promote: !asis)

  args.each do |file|
    puts "#{file}:" unless args.size == 1
    begin
      result = Bun::File.examination(file, exam, options)
      puts result[:result].to_s unless options[:quiet]
      if options[:save] && !File.binary?(file)
        Bun::File::Unpacked.mark(file, {options[:save]=>result[:result]}.inspect)
      end
      code = result[:code]
      if options[:value]
        code = options[:value] == result[:result] ? 0 : 1
      end
      exit(code || 0)
    rescue Expression::EvaluationError => e
      stop "!Evaluation error: #{e}"
    rescue String::Examination::Invalid => e
      warn "!#{options[:exam]} is an invalid analysis: #{e}" unless options[:quiet]
      exit(99)
    end
  end
end