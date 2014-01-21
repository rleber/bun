#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "show [OPTIONS] EXAMINATIONS... FILES...", "Analyze the contents of files"
option 'asis',    :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to decode file"
# TODO Needs some explanation
option 'case',    :aliases=>'-c', :type=>'boolean', :desc=>"Case insensitive"
option 'file',    :aliases=>'-f', :type=>'boolean', :desc=>"Always include file path in results"
option 'format',  :aliases=>'-F', :type=>'string',  :desc=>"Use other formats", :default=>'text'
option 'if',      :aliases=>'-i', :type=>'string',  :desc=>"Only show the result for files which match this expression"
option 'inspect', :aliases=>'-I', :type=>'boolean', :desc=>"Just echo back the value of --exam as received"
option 'justify', :aliases=>'-j', :type=>'boolean', :desc=>"Line up the text neatly"
# TODO Better syntax for this?
option 'min',     :aliases=>'-M', :type=>'numeric', :desc=>"For counting examinations: minimum count"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
option 'raise',   :aliases=>'-r', :type=>'boolean', :desc=>"Allow expression evaluations to raise exceptions"
option 'save',    :aliases=>'-s', :type=>'string',  :desc=>"Save the result under this name as a mark in the file"
option 'titles',  :aliases=>'-t', :type=>'boolean', :desc=>"Always include column titles in print listing"
option 'usage',   :aliases=>'-U', :type=>'boolean', :desc=>"List usage information"
# TODO Is this still necessary?
option 'unless',  :aliases=>'-u', :type=>'string',  :desc=>"Only show the result for files which do not match this expression"
option 'value',   :aliases=>'-v', :type=>'string',  :desc=>"Set the return code based on whether the" +
                                                           " result matches this value"
long_desc <<-EOT
Examine the contents or characteristics of files.

Many analyses are available via the EXAMINATION parameter. See --usage for more detail.

If more than one EXAMINATION is provided, then they must be separated from the FILES by the marker --in.

Available formats are: #{Bun::Formatter.valid_formats.join(', ')}

EOT
def show(*args)
  # Check for separator ('--in') between exams and files
  exams, files = split_arguments_at_separator('--in', *args, assumed_before: 1)
  check_for_unknown_options(*exams, *files)

  if options[:usage]
    puts String::Examination.usage
    exit
  end

  if_clause = [(options[:if] ? "(#{options[:if]})" : nil), (options[:unless] ? "!(#{options[:unless]})" : nil)] \
              .compact.join("&&")
  if_clause = nil if if_clause==''
  format = options[:format].to_sym

  stop "!First argument should be an examination expression" unless exams.size > 0
  
  if options[:inspect]
    puts exams
    exit
  end

  stop "!Must provide at least one file " unless files.size > 0

  opts = options.dup # Weird behavior of options here
  asis = opts.delete(:asis)
  options = opts.merge(promote: !asis)

  files = files.map do |file|
    file, shard = Bun::File.get_shard(file)
    stop "!File #{file} does not exist" unless File.exists?(file) || file=='-'
    res = if File.directory?(file)
      Archive.new(file).leaves.to_a
    else
      [file]
    end
    if shard
      res.map!{|f| "#{f}[#{shard}]"}
    end
    res
  end.flatten

  last_values = nil
  Formatter.open('-', justify: options[:justify], format: format) do |formatter|
    files.each do |file|
      file, shard = Bun::File.get_shard(file)
      options.merge!(shard: shard)
      next if if_clause && !value_of(if_clause, file, options)
      last_values = values = exams.map {|exam| value_of(exam, file, options) }
      unless options[:quiet]
        matrixes = values.map{|value| value.to_matrix }
        if formatter.count == 0
          right_columns = []
          column_count = 0
          values.each.with_index do |value, i|
            cols = value.right_justified_columns
            right_columns += cols.map{|col| col + column_count}
            column_count += (matrixes[i].first || []).size
          end
          titles = values.map{|value| value.titles || ['Value']}.flatten
          if options[:file] || files.size > 1
            titles.unshift("File")
            right_columns = right_columns.map{|col| col+1}
          end
          formatter.right_justified_columns = right_columns
          formatter.titles = titles if options[:titles] || (files.size >1 && column_count > 1)
        end
        if files.size > 1 || options[:file]
          m_rows = matrixes.map {|matrix| matrix.size }.max
          # Insert file names in first column
          file_matrix = if m_rows == 0
            [] # Do nothing
          elsif (format == :text && options[:justify])
            [[File.expand_path(file)]] + [['']]*(m_rows-1) # File name only in first row
          else
            [[File.expand_path(file)]]*m_rows # File name in all rows
          end
          matrixes.unshift file_matrix
        end
        m = matrixes.matrix_join
        m.each {|row| formatter << row }
      end
      if options[:save] && !File.binary?(file)
        Bun::File::Unpacked.mark(file, {options[:save]=>value}.inspect)
      end
    end
  end
  if last_values && last_values.size == 1
    code = last_values.first.code
    if options[:value]
      value = last_values.first.value rescue nil
      code = options[:value] == value ? 0 : 1
    end
    exit(code || 0)
  end
end

no_tasks do
  # TODO Opportunity to DRY this out?
  def value_of(expr, file, options={})
    Bun::File.examination(file, expr, options).value_for_bot(options)
  end
end
