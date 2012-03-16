desc "dump ARCHIVE FILE", "Uncompress a frozen Honeywell file"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option "escape",  :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
option "lines",   :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
option "offset",  :aliases=>'-o', :type=>'numeric', :desc=>'Skip the first n lines'
option "thawed",  :aliases=>'-t', :type=>'boolean', :desc=>'Display the file in partially thawed format'
def dump(file_name, n)
  limit = options[:lines]
  directory = options[:archive] || Archive.location
  archive = Archive.new(directory)
  file = archive.open(file_name)
  abort "!File #{file_name} is an archive of #{archived_file}, which is not frozen." unless file.file_type == :frozen
  archived_file = file.path
  archived_file = "--unknown--" unless archived_file
  file_index = file.shard_index(n)
  puts "Archive for file_name #{file.shard_name(file_index)}:"
  if options[:thawed]
    lines = file.lines(file_index)
    # TODO Refactor using Array#justify_rows
    offset_width = ('%o'%lines[-1][:offset]).size
    lines.each do |l|
      offset = '0' + ("%0#{offset_width}o" % l[:offset])
      descriptor = l[:descriptor]
      top_bits = File::Frozen.top_descriptor_bits(descriptor)
      clipped_length = File::Frozen.clipped_line_length(descriptor)
      bottom_bits = File::Frozen.bottom_descriptor_bits(descriptor)
      flag = File::Frozen::good_descriptor?(descriptor) ? ' ' : '!'
      puts "#{offset} #{'%012o'%descriptor} " + 
           "#{'%03o'%top_bits}|#{'%03o'%clipped_length} #{flag} " +
           "#{l[:raw].inspect[1..-2]}"
    end
  else
    content = file.shard_words(file_index)
    Dump.dump(content, options.merge(:frozen=>true))
  end
end
