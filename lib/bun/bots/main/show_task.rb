#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "show [OPTIONS] EXPRESSIONS... FILES...", "Analyze the contents of files"
option 'asis',    :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to decode file"
option 'format',  :aliases=>'-F', :type=>'string',  :desc=>"Use other formats", :default=>'text'
option 'if',      :aliases=>'-i', :type=>'string',  :desc=>"Only show the result for files which match this expression"
option 'inspect', :aliases=>'-I', :type=>'boolean', :desc=>"Just echo back the value of --trait as received"
option 'justify', :aliases=>'-j', :type=>'boolean', :desc=>"Line up the text neatly"
option 'order',   :aliases=>'-o', :type=>'string',  :desc=>"Sort in the order of this expression (may have prefix)"
option 'inspect', :aliases=>'-I', :type=>'boolean', :desc=>"Just echo back the value of --trait as received"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
option 'raise',   :aliases=>'-r', :type=>'boolean', :desc=>"Allow expression evaluations to raise exceptions"
option 'save',    :aliases=>'-s', :type=>'string',  :desc=>"Save the result under this name as a mark in the file"
option 'titles',  :aliases=>'-t', :type=>'boolean', :desc=>"Always include column titles in print listing"
option 'usage',   :aliases=>'-U', :type=>'boolean', :desc=>"List usage information"
option 'unless',  :aliases=>'-u', :type=>'string',  :desc=>"Only show the result for files which do not match this expression"
# TODO Is this still necessary?
option 'value',   :aliases=>'-v', :type=>'string',  :desc=>"Set the return code based on whether the" +
                                                           " result matches this value"
option 'where',   :aliases=>'-w', :type=>'string',  :desc=>"Synonym for --if"
long_desc <<-EOT
Examine the contents or characteristics of files.

Many analyses are available via the EXAMINATION parameter. See --usage for more detail.

If more than one EXAMINATION is provided, then they must be separated from the FILES by the marker --in.

--if and --where are synonyms, and --unless is the opposite. They may all be used, in which case results are only
included if all three tests pass. Example: bun show ... --if 'type==:frozen' --unless 'block_count > 3'

--order allows you to provide a sort order for results. It can be any Ruby expression, similar to the EXPRESSIONS
arguments. It may (optionally) be preceded with a prefix like "asc:" or "desc:" to specify sort order.

Available formats are: #{Bun::Formatter.valid_formats.join(', ')}

EOT
def show(*args)
  # Check for separator ('--in') between traits and files
  traits, files = split_arguments_at_separator('--in', *args, assumed_before: 1)
  check_for_unknown_options(*traits, *files)

  if options[:usage]
    puts String::Trait.usage
    exit
  end

  if_clause = [
                (options[:if] ? "(#{options[:if]})" : nil), 
                (options[:where] ? "(#{options[:where]})" : nil), 
                (options[:unless] ? "!(#{options[:unless]})" : nil)] \
              .compact.join("&&")
  if_clause = nil if if_clause==''
  format = options[:format].to_sym

  stop "!First argument should be an trait expression" unless traits.size > 0
  
  if options[:inspect]
    puts traits
    puts "--if #{options[:if]}" if options[:if]
    puts "--where #{options[:where]}" if options[:where]
    puts "--unless #{options[:unless]}" if options[:where]
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

  traits.unshift('file') if files.size>1 && !traits.include?('file')

  if options[:order] # Fetch the data once, and sort it, then display it later
    if options[:order] =~ /^\s*(asc|desc|a|d|ascending|descending):(.*)$/i
      order_direction = $1[0].downcase == 'a' ? +1 : -1
      order_expression = $2
    else
      order_direction = +1
      order_expression = options[:order]
    end
    traits.push 'file'
    traits.push order_expression

    value_list = files.map do |file|
      file, shard = Bun::File.get_shard(file)
      options.merge!(shard: shard)
      if if_clause
        v = value_of(if_clause, file, options)
        v = v.value.value if v.respond_to?(:to_matrix) # Get rid of wrapper
        next unless v
      end
      traits.map {|trait| value_of(trait, file, options) }
    end.compact # Because next above will cause nils to be inserted

    value_list = value_list.sort do |traits1, traits2|
      v1 = unwrap(traits1.last)
      v2 = unwrap(traits2.last)
      # Sort nils at top
      comparison = if v1.nil?
        v2.nil? ? 0 : -1
      else
        v2.nil? ? 1 : (v1<=>v2)
      end
      comparison ||= v1.object_id <=> v2.object_id # If all else fails, this should be consistent
      if comparison == 0
        comparison = unwrap(traits1[-2]) <=> unwrap(traits2[-2]) # Break ties with file paths
      end
      order_direction*comparison
    end
    value_list.map!{|traits| traits[0..-2]} # Drop the sort field

    # Now output
    # TODO DRY this up
    last_values = nil
    Formatter.open('-', justify: options[:justify], format: format) do |formatter|
      value_list.each do |values|
        file = values.pop
        last_values = values
        output_values(formatter, values, titles: options[:titles]) unless options[:quiet]
        if options[:save] && !File.binary?(file)
          Bun::File::Unpacked.mark(file, {options[:save]=>value}.inspect)
        end
      end
    end
  else # Not sorted
    last_values = nil
    Formatter.open('-', justify: options[:justify], format: format) do |formatter|
      files.each do |file|
        file, shard = Bun::File.get_shard(file)
        options.merge!(shard: shard)
        if if_clause
          next unless unwrap(value_of(if_clause, file, options))
        end

        last_values = values = traits.map {|trait| value_of(trait, file, options) }
        output_values(formatter, values, titles: options[:titles]) unless options[:quiet]
        if options[:save] && !File.binary?(file)
          Bun::File::Unpacked.mark(file, {options[:save]=>value}.inspect)
        end
      end
    end
  end
  if last_values && last_values.size == 1
    code = last_values.first.code
    if options[:value]
      value = unwrap(last_values.first) rescue nil
      code = options[:value] == value ? 0 : 1
    end
    exit(code || 0)
  end
end

no_tasks do
  def unwrap(value)
    String::Trait::Base.unwrap(value)
  end

  # TODO Opportunity to DRY this out?
  def value_of(expr, file, options={})
    Bun::File.trait(file, expr, options).value(options)
  rescue Bun::Expression::EvaluationError => e 
    stop "!Expression error: #{e}"
  end

  def output_values(formatter, values, options={})
    # TODO Simplify this
    matrixes = values.map{|value| value.respond_to?(:to_matrix) ? value.to_matrix : [[value]]}
    if formatter.count == 0
      right_columns = []
      column_count = 0
      values.each.with_index do |value, i|
        # TODO Simplify this
        cols = if value.respond_to?(:right_justified_columns)
          value.right_justified_columns
        else
          value.is_a?(Numeric) ? [0]: []
        end
        right_columns += cols.map{|col| col + column_count}
        column_count += (matrixes[i].first || []).size
      end
      titles = values.map{|value| value.titles || ['Value']}.flatten
      formatter.right_justified_columns = right_columns
      formatter.titles = titles if options[:titles] || (column_count > 1 && options[:titles] != false)
    end
    m = matrixes.matrix_join
    m.each {|row| formatter << row }
  end
end
