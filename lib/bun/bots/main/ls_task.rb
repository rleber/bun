#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

no_tasks do
  def get_regexp(pattern)
    Regexp.new(pattern)
  rescue
    nil
  end
end

SORT_VALUES = %w{tape file type updated description size}
SORT_FIELDS = {
  :description => :description,
  :file        => :path,
  :size        => :file_size,
  :tape        => :tape,
  :type        => :file_type,
  :updated     => :file_time,
}
TYPE_VALUES = %w{all frozen text huff}
DATE_FORMAT = '%Y/%m/%d'
TIME_FORMAT = DATE_FORMAT + ' %H:%M:%S'
FIELD_CONVERSIONS = {
  :file_time   => lambda {|f| f.nil? ? 'n/a' : f.strftime(f.is_a?(Time) ? TIME_FORMAT : DATE_FORMAT) },
  :file_type   => lambda {|f| f.to_s.sub(/^./) {|m| m.upcase} },
  :shard_count => lambda {|f| f==0 ? '' : f },
}
FIELD_HEADINGS = {
  :description   => 'Description',
  :file_size     => 'Size',
  :file_type     => 'Type',
  :path          => 'File',
  :shard_count   => 'Shards',
  :tape          => 'Tape',
  :tape_path     => 'Tape',
  :file_time     => 'Updated',
}
DEFAULT_VALUES = {
  :file_size   => 0,
  :shard_count => 0,
  :file_time   => Time.now,
}
SHARD_FIELDS = {
  :file_size     => :size,
  :shard_count   => '',
  :file_type     => 'Shard',
  # :updated       => :file_time,
}

# TODO --recursive option

desc "ls FILE...", "Display an index of archived files"
option "descr",     :aliases=>"-d", :type=>'boolean',                              :desc=>"Include description"
option "files",     :aliases=>"-f", :type=>'string',  :default=>'',                :desc=>"Show only files that match this Ruby Regexp, e.g. 'f.*oo\\.rb$'"
option "frozen",    :aliases=>"-r", :type=>'boolean',                              :desc=>"Recursively include contents of freeze files"
option "long",      :aliases=>"-l", :type=>'boolean',                              :desc=>"Display long format (incl. text vs. frozen)"
option 'path',      :aliases=>'-p', :type=>'boolean',                              :desc=>"Display paths for tape files"
option 'onecolumn', :aliases=>'-o', :type=>'boolean',                              :desc=>"Display tape names only"
option "sort",      :aliases=>"-s", :type=>'string',  :default=>SORT_VALUES.first, :desc=>"Sort order(s) for files (#{SORT_VALUES.join(', ')})"
option "type",      :aliases=>"-T", :type=>'string',  :default=>TYPE_VALUES.first, :desc=>"Show only files of this type (#{TYPE_VALUES.join(', ')})"
# TODO Refactor tape/file patterns; use tape::file::shard syntax
# TODO Refactor code into shorter submethods
def ls(*paths)
  type_pattern = case options[:type].downcase
    when 'f', 'frozen'
      /^(frozen|shard)$/i
    when 't', 'text'
      /^text$/i
    when 'h', 'huff', 'huffman'
      /^huffman$/i
    when '*','a','all'
      //
    else
      stop "!Unknown --type setting. Should be one of #{TYPE_VALUES.join(', ')}"
    end
  file_pattern = get_regexp(options[:files])
  stop "!Invalid --files pattern. Should be a valid Ruby regular expression (except for the delimiters)" unless file_pattern

  fields =  options[:path] ? [:tape_path] : [:tape]
  fields += [:path] unless options[:onecolumn]
  fields += [:file_type] if options[:type]
  fields += [:file_type, :file_time, :file_size] if options[:long]
  fields += [:shard_count] if options[:long]
  fields += [:description] if options[:descr]
  fields = fields.uniq

  if options[:sort]
    sort_fields = options[:sort].split(',').map do |sort_field|
      sort_field = SORT_FIELDS[sort_field.strip.to_sym]
      stop "!Unknown --sort setting. Must be one of #{SORT_VALUES.join(', ')}" unless sort_field
      sort_field.to_sym
    end
  else
    sort_fields = []
  end
  sort_fields += [:tape, :path]
  if options[:onecolumn]
    sort_fields = [:tape]
  end
  if options[:path]
    sort_fields = sort_fields.map {|f| f==:tape ? :tape_path : f }
  end
  sort_fields.each do |sort_field|
    stop "!Can't sort by #{sort_field}. It isn't included in this format" unless fields.include?(sort_field)
  end
  
  # Expand directories, if given as parameters
  paths = paths.map {|path| File.directory?(path) ? Dir.glob("#{path}/*") : path }.flatten

  # Retrieve file information
  if options[:onecolumn] && !options[:frozen] && type_pattern==// && !options[:path]
    output = options[:path] ? paths : paths.map{|p| File.basename(p) }
    puts output
    return
  end
  file_info = []
  files = paths.each_with_index do |tape, i|
    file_descriptor = File.descriptor(tape)
    file_row = fields.inject({}) do |hsh, f|
      # TODO This is a little smelly
      value = case f
      when :shard_count
        file_descriptor[:shards] && file_descriptor[:shards].count
      when :file_time
        [file_descriptor[:catalog_time], file_descriptor[:file_time]].compact.min
      else 
        file_descriptor[f]
      end
      hsh[f] = value
      hsh
    end
    file_info << file_row
    if options[:frozen] && file_descriptor.file_type == :frozen
      file_descriptor.shards.each do |d|
        file_info << fields.inject({}) do |hsh, f|
          new_f = SHARD_FIELDS[f] || f
          hsh[f] = if new_f==:path
            File.join(file_descriptor[:path], d[:name])
          elsif new_f.is_a?(Symbol)
            d[new_f] || file_descriptor[new_f] 
          else
            new_f
          end
          hsh
        end
      end
    end
  end
  
  file_info = file_info.select{|file| file[:file_type].to_s=~type_pattern && file[:path]=~file_pattern }
  sorted_info = file_info.sort_by do |fi|
    sort_fields.map{|f| fi[f].nil? ? DEFAULT_VALUES[f]||'' : fi[f] }
  end
  
  formatted_info = sorted_info
  formatted_info.each do |fi|
    fi.keys.each do |k|
      fi[k] = FIELD_CONVERSIONS[k].call(fi[k]) if FIELD_CONVERSIONS[k]
    end
  end

  table = []
  fields -= [:file_type] unless options[:long]
  headings = FIELD_HEADINGS.values_at(*fields)
  table << headings
  formatted_info.each do |entry|
    table << entry.values_at(*fields)
  end
  table = table.justify_rows
  # TODO Move right justification to Array#justify_rows
  [:file_size, :shard_count].each do |f|
    if ix = fields.index(f)
      table.each do |row|
        row[ix] = row[ix].to_s
        row[ix] = (' '*(row[ix].size) + row[ix].strip)[-(row[ix].size)..-1] # Right justify
      end
    end
  end
  if table.size <= 1
    puts "No matching files"
  else
    table.each do |row|
      puts row.join('  ')
    end
  end  
end