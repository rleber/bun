#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "find FILES", "Find and print all the files matching certain criteria"
option 'asis',    :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to decode files"
option 'case',    :aliases=>'-c', :type=>'boolean', :desc=>"Case insensitive"
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"With --copy: don't actually copy files"
option 'copy',    :aliases=>'-C', :type=>'string',  :desc=>"Copy selected files to this location"
option 'exam',    :aliases=>'-e', :type=>'string',  :desc=>"What test? See bun help check for options"
option 'field',   :aliases=>'-F', :type=>'string',  :desc=>"Find based on the value in a field"
option 'formula', :aliases=>'-f', :type=>'string',  :desc=>"Evaluate a Ruby formula -- see help"
option 'list',    :aliases=>'-l', :type=>'boolean', :desc=>"List the defined examinations"
option 'match',   :aliases=>'-m', :type=>'string',  :desc=>"Matches this regular expression (Ruby format)"
option 'min',     :aliases=>'-M', :type=>'numeric', :desc=>"For counting examinations: minimum count"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode; really only makes sense with --copy"
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

  stop "!Must specify at least one file" if files.size==0

  option_count = [:exam, :formula, :match].inject(0) {|sum, option| sum += 1 if options[option]; sum }
  stop "!Cannot have more than one of --exam, --formula and --match" if option_count > 1
  stop "!Must do one of --exam, --formula or --match" if option_count == 0

  stop "!Can't use --copy if more than one file is specified" if options[:copy] && files.size > 1
  stop "!When using --copy, expect file to be a directory" if options[:copy] && !File.directory?(files.first)
  
  opts = options.dup # Weird behavior of options here
  asis = opts.delete(:asis)
  options = opts.merge(promote: !asis)
  if options[:copy]
    from_archive = Archive.new(files.first)
    to_archive = Archive.new(options[:copy])
    shell = Shell.new
    shell.rm_rf(to_archive)
  end

  begin
    Archive.examine_select(files, options) do |result| 
      puts result[:file] unless options[:copy] || options[:quiet]
      if options[:copy]
        from_file = result[:file]
        relative_from_file = from_archive.relative_path(from_file)
        to_file = to_archive.expand_path(relative_from_file)
        puts "Copy #{relative_from_file} => #{to_file}" unless options[:quiet]
        unless options[:dryrun]
          shell.mkdir_p(File.dirname(to_file))
          shell.cp_r(from_file, to_file)
        end
      end
    end
  rescue Formula::EvaluationError => e
    stop "!#{e}"
  end
end
