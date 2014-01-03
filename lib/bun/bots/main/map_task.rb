#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "map FILES", "Print a list of files, along with the examined value"
option 'asis',    :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to decode files"
option 'case',    :aliases=>'-c', :type=>'boolean', :desc=>"Case insensitive"
option 'exam',    :aliases=>'-e', :type=>'string',  :desc=>"What test? See bun help check for options"
option 'formula', :aliases=>'-f', :type=>'string',  :desc=>"Evaluate a Ruby formula -- see help"
option 'justify', :aliases=>'-j', :type=>'boolean', :desc=>"Justify the rows"
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
def map(*files)
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

  file_column_size = 0
  max_columns = 0
  table = []
  last_result = nil
  Archive.examine_map(files, options) do |result| 
    file_column_size = [file_column_size, result[:file].size].max
    last_result = result[:result]
    row = [result[:file], result[:result]].flatten
    max_columns = [max_columns, row.size].max
    if options[:justify]
      table << row
    else
      puts row.join('  ')
    end
  end
  if options[:justify] && max_columns > 0 # i.e. at least one row
    titles = case max_columns
    when 1
      nil
    when 2
      %w{File Result}
    else
      ['File'] + (1..max_columns).map {|i| "Result #{i}"}
    end
    if titles
      if last_result.respond_to?(:titles)
        # Splice the titles together
        (titles.size...max_columns).each do |i|
          titles += last_result.titles[i]
        end
      end
      table.unshift titles
    end
    puts table.justify_rows.map {|row| row.join('  ')}
  end
end
