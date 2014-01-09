#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "same FILES", "Group files which match on a certain criterion"
option 'asis',    :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to decode files"
option 'case',    :aliases=>'-c', :type=>'boolean', :desc=>"Case insensitive"
option 'exam',    :aliases=>'-e', :type=>'string',  :desc=>"What test? See bun help check for options"
option 'field',   :aliases=>'-F', :type=>'string',  :desc=>"Return the value in a field"
option 'formula', :aliases=>'-f', :type=>'string',  :desc=>"Evaluate a Ruby formula -- see help"
option 'justify', :aliases=>'-j', :type=>'boolean', :desc=>"Justify the rows"
option 'list',    :aliases=>'-l', :type=>'boolean', :desc=>"List the defined examinations"
option 'min',     :aliases=>'-m', :type=>'numeric', :desc=>"For counting examinations: minimum count"
option 'text',    :aliases=>'-x', :type=>'boolean', :desc=>"Based on the text in the file"
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
def same(*files)
  if options[:list]
    puts String::Examination.exam_definition_table
    exit
  end

  option_count = [:exam, :field, :formula, :match, :text] \
      .inject(0) {|sum, option| sum += 1 if options[option]; sum }
  stop "!Cannot have more than one of --exam, --field, --formula, --match, and --text" if option_count > 1
  stop "!Must do one of --exam, --field, --formula, --match, or --text" if option_count == 0
  
  opts = options.dup # Weird behavior of options here
  asis = opts.delete(:asis)
  options = opts.merge(promote: !asis)

  max_columns = 0
  table = []
  
  # TODO DRY this up (same logic in map_task)
  Archive.examine_map(files, options) do |result| 
    last_result = result[:result]
    if result[:result].respond_to?(:value) && result[:result].value.class < Hash
      row = [result[:file], result[:result].value.values].flatten
    else
      row = [result[:file], result[:result]].flatten
    end
    max_columns = [max_columns, row.size].max
    table << row
  end
  
  puts "Uniqueness counts"
  puts "#{table.size} rows in table"
  puts "#{table.uniq {|row| row[1..-1]}.size} uniq rows in table"
  puts ""
  table = table.sort_by{|row| row.rotate }
  last_row = []
  table.each do |row|
    if row[1..-1] == last_row[1..-1]
      puts row.rotate.join('  ')
    end
    last_row = row
  end
end
