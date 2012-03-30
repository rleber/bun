#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO Thaw all files
desc "thaw ARCHIVE FILE [TO]", "Uncompress a frozen Honeywell file"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option "log",     :aliases=>'-l', :type=>'string',  :desc=>"Log status to specified file"
option "warn",    :aliases=>"-w", :type=>"boolean", :desc=>"Warn if bad data is found"
long_desc <<-EOT
FILE may have some special formats: '+-nnn' (where nnn is an integer) denotes file number nnn. '-nnn' denotes the nnnth
file from the end of the archive. Anything else denotes the name of a file. A backslash character is ignored at the
beginning of a file name, so that '\\+1' refers to a file named '+1', whereas '+1' refers to the first file in the archive,
whatever its name.
EOT
def thaw(file_name, n, out=nil)
  archive = Archive.new(:at=>options[:archive])
  directory = archive.at
  file = archive.open(file_name)
  begin
    stop "!File #{file_name} is an archive of #{archived_file}, which is not frozen." unless file.file_type == :frozen
    archived_file = file.path
    archived_file = "--unknown--" unless archived_file
    content = file.shards.at(file.shard_index(n))
    shell = Shell.new
    shell.write out, content, :timestamp=>file.file_time, :quiet=>true
    warn "Thawed with #{file.errors.count} decoding errors" if options[:warn] && file.errors > 0
    shell.log options[:log], "thaw #{out.inspect} from #{file_name.inspect} with #{file.errors.count} errors" if options[:log]
  ensure
    file.close
  end
end