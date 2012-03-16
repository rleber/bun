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
  :tape        => :tape_name,
  :type        => :file_type,
  :updated     => :updated,
}
TYPE_VALUES = %w{all frozen text huff}
DATE_FORMAT = '%Y/%m/%d'
TIME_FORMAT = DATE_FORMAT + ' %H:%M:%S'
FIELD_CONVERSIONS = {
  :updated     => lambda {|f| f.nil? ? 'n/a' : f.strftime(f.is_a?(Time) ? TIME_FORMAT : DATE_FORMAT) },
  :file_type   => lambda {|f| f.to_s.sub(/^./) {|m| m.upcase} },
  :shard_count => lambda {|f| f==0 ? '' : f },
}
FIELD_HEADINGS = {
  :description => 'Description',
  :file_size   => 'Size',
  :file_type   => 'Type',
  :path        => 'File',
  :shard_count => 'Shards',
  :tape_name   => 'Tape',
  :tape_path   => 'Tape',
  :updated     => 'Updated',
}
DEFAULT_VALUES = {
  :file_size   => 0,
  :shard_count => 0,
  :updated     => Time.now,
}

# TODO Reorder tasks (split in separate files?)
desc "ls", "Display an index of archived files"
option 'archive', :aliases=>'-a', :type=>'string',                               :desc=>'Archive location'
option "build",   :aliases=>"-b", :type=>'boolean',                              :desc=>"Don't rely on archive index; always build information from source file"
option "descr",   :aliases=>"-d", :type=>'boolean',                              :desc=>"Include description"
option "files",   :aliases=>"-f", :type=>'string',  :default=>'',                :desc=>"Show only files that match this Ruby Regexp, e.g. 'f.*oo\\.rb$'"
option "frozen",  :aliases=>"-r", :type=>'boolean',                              :desc=>"Recursively include contents of freeze files"
option "long",    :aliases=>"-l", :type=>'boolean',                              :desc=>"Display long format (incl. text vs. frozen)"
option 'path',    :aliases=>'-p', :type=>'boolean',                              :desc=>"Display paths for tape files"
option "sort",    :aliases=>"-s", :type=>'string',  :default=>SORT_VALUES.first, :desc=>"Sort order for files (#{SORT_VALUES.join(', ')})"
option "tapes",   :aliases=>"-t", :type=>'string',  :default=>'',                :desc=>"Show only tapes that match this Ruby Regexp, e.g. 'f.*oo\\.rb$'"
option "type",    :aliases=>"-T", :type=>'string',  :default=>TYPE_VALUES.first, :desc=>"Show only files of this type (#{TYPE_VALUES.join(', ')})"
# TODO Refactor tape/file patterns; use tape::file::shard syntax
# TODO Speed this up; esp. ls with no options
def ls
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
      abort "!Unknown --type setting. Should be one of #{TYPE_VALUES.join(', ')}"
    end
  file_pattern = get_regexp(options[:files])
  abort "!Invalid --files pattern. Should be a valid Ruby regular expression (except for the delimiters)" unless file_pattern
  tape_pattern = get_regexp(options[:tapes])
  abort "!Invalid --tapes pattern. Should be a valid Ruby regular expression (except for the delimiters)" unless tape_pattern
  directory = options[:archive] || Archive.location

  fields =  options[:path] ? [:tape_path] : [:tape_name]
  fields += [:file_type, :updated, :file_size] if options[:long]
  fields += [:path]
  fields += [:shard_count] if options[:long]
  fields += [:description] if options[:descr]

  if options[:sort]
    sort_field = SORT_FIELDS[options[:sort].to_sym]
    abort "!Unknown --sort setting. Must be one of #{SORT_VALUES.join(', ')}" unless sort_field
    sort_fields = [sort_field.to_sym, :tape_name, :path]
  else
    sort_fields = [:tape_name, :path]
  end
  if options[:path]
    sort_fields = sort_fields.map {|f| f==:tape_name ? :tape_path : f }
  end
  sort_fields.each do |sort_field|
    abort "!Can't sort by #{sort_field}. It isn't included in this format" unless fields.include?(sort_field)
  end

  # Retrieve file information
  archive = Archive.new(directory)
  ix = archive.tapes
  # TODO Refactor using archive.select
  ix = ix.select{|tape_name| tape_name =~ tape_pattern}
  file_info = []
  files = ix.each_with_index do |tape_name, i|
    file_descriptor = archive.descriptor(tape_name, :build=>options[:build])
    file_row = fields.inject({}) {|hsh, f| hsh[f] = file_descriptor[f]; hsh }
    file_info << file_row
    if options[:frozen] && file_descriptor[:file_type] == :frozen
      file_descriptor[:shards].each do |d|
        file_info << fields.inject({}) {|hsh, f| hsh[f] = d[f]; hsh }
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
        row[ix] = (' '*(row[ix].size) + row[ix].strip)[-(row[ix].size)..-1] # Right justify
      end
    end
  end
  puts "Archive at #{directory}:"
  if table.size <= 1
    puts "No matching files"
  else
    table.each do |row|
      puts row.join('  ')
    end
  end  
end
