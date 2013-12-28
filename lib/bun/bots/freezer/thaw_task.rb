#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO Thaw all files
desc "thaw FILE SHARD [TO]", "Uncompress a frozen Honeywell file"
option "bare",    :aliases=>"-b", :type=>"boolean", :desc=>"Do not create an index entry for the thawed file"
option "warn",    :aliases=>"-w", :type=>"boolean", :desc=>"Warn if bad data is found"
long_desc <<-EOT
FILE may have some special formats: '+-nnn' (where nnn is an integer) denotes file number nnn. '-nnn' denotes the nnnth
file from the end of the archive. Anything else denotes the name of a file. A backslash character is ignored at the
beginning of a file name, so that '\\+1' refers to a file named '+1', whereas '+1' refers to the first file in the archive,
whatever its name.
EOT
def thaw(file, n, out=nil)
  at = File.dirname(file)
  file_name = File.basename(file)
  # TODO Is the Archive object even necessary here?
  
  archive = Archive.new(at)
  directory = archive.at
  file = archive.open(file_name)
  stop "!File #{file_name} is not frozen." unless file.file_type == :frozen
  begin
    file.extract(n, out, :bare=>options[:bare])
    warn "Thawed with #{file.errors.count} decoding errors" if options[:warn] && file.errors > 0
  ensure
    file.close
  end
end