# TODO Thaw all files
desc "thaw ARCHIVE FILE [TO]", "Uncompress a frozen Honeywell file"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option "log",     :aliases=>'-l', :type=>'string',  :desc=>"Log status to specified file"
option "strict",  :aliases=>"-s", :type=>"boolean", :desc=>"Check for bad data. Abort if found"
option "warn",    :aliases=>"-w", :type=>"boolean", :desc=>"Warn if bad data is found"
long_desc <<-EOT
FILE may have some special formats: '+-nnn' (where nnn is an integer) denotes file number nnn. '-nnn' denotes the nnnth
file from the end of the archive. Anything else denotes the name of a file. A backslash character is ignored at the
beginning of a file name, so that '\\+1' refers to a file named '+1', whereas '+1' refers to the first file in the archive,
whatever its name.
EOT
def thaw(file_name, n, out=nil)
  directory = options[:archive] || Archive.location
  archive = Archive.new(directory)
  file = archive.open(file_name)
  stop "!File #{file_name} is an archive of #{archived_file}, which is not frozen." unless file.file_type == :frozen
  archived_file = file.path
  archived_file = "--unknown--" unless archived_file
  content = file.shard(file.shard_index(n))
  shell = Shell.new
  shell.write out, content, :timestamp=>file.file_time, :quiet=>true
  warn "Thawed with #{file.errors} decoding errors" if options[:warn] && file.errors > 0
  shell.log options[:log], "thaw #{out.inspect} from #{file_name.inspect} with #{file.errors} errors" if options[:log]
end
