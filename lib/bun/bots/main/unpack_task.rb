desc "unpack TAPE [TO]", "Unpack a file (Not frozen files -- use freezer subcommands for that)"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option "delete",  :aliases=>'-d', :type=>'boolean', :desc=>"Keep deleted lines"
option "inspect", :aliases=>'-i', :type=>'boolean', :desc=>"Display long format details for each line"
option "log",     :aliases=>'-l', :type=>'string',  :desc=>"Log status to specified file"
option "warn",    :aliases=>'-w', :type=>'boolean', :desc=>"Warn if there are decoding errors"
# TODO combine with other forms of read (e.g. thaw)
# TODO rename bun read
def unpack(file_name, to=nil)
  directory = options[:archive] || Archive.location
  archive = Archive.new(directory)
  file = archive.open(file_name)
  file.keep_deletes = true if options[:delete]
  archived_file = file.path
  abort "!Can't unpack #{file_name}. It contains a frozen file_name: #{archived_file}" if file.file_type == :frozen
  if options[:inspect]
    lines = []
    file.lines.each do |l|
      # p l
      # exit
      start = l[:start]
      line_descriptor = l[:descriptor]
      line_length = line_descriptor.half_word[0]
      line_flags = line_descriptor.half_word[1]
      line_codes = []
      line_codes << 'D' if l[:status]==:deleted
      line_codes << '+' if line_length > 0777 # Upper bits not zero
      line_codes << '*' if (line_descriptor & 0777) != 0600 # Bottom descriptor byte is normally 0600
      lines << %Q{#{"%06o" % start}: len #{"%06o" % line_length} (#{"%6d" % line_length}) [#{'%06o' % line_flags} #{'%-3s' % (line_codes.join)}] #{l[:raw].inspect}}
    end
    content = lines.join("\n")
  else
    content = file.text
  end
  shell = Shell.new
  shell.write to, content
  warn "Unpacked with #{file.errors} errors" if options[:warn] && file.errors > 0
  shell.log options[:log], "unpack #{to.inspect} from #{file_name.inspect} with #{file.errors} errors" if options[:log]
end
