#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "unpack LOCATION [TO]", "Unpack a file (Not frozen files -- use freezer subcommands for that)"
option 'at',      :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option "bare",    :aliases=>"-b", :type=>"boolean", :desc=>"Do not create an index entry for the unpacked file"
option "delete",  :aliases=>'-d', :type=>'boolean', :desc=>"Keep deleted lines"
option "inspect", :aliases=>'-i', :type=>'boolean', :desc=>"Display long format details for each line"
option "warn",    :aliases=>'-w', :type=>'boolean', :desc=>"Warn if there are decoding errors"
# TODO combine with other forms of read (e.g. thaw)
# TODO rename bun read
def unpack(file_name, to=nil)
  archive = Archive.new(options)
  file = archive.open(file_name)
  begin
    file.keep_deletes = true if options[:delete]
    archived_file = file.path
    stop "!Can't unpack #{file_name}. It contains a frozen file_name: #{archived_file}" if file.file_type == :frozen
    content = options[:inspect] ? file.inspect : file.text
    shell = Shell.new
    shell.write to, content
    file.copy_descriptor(to, :extracted=>Time.now) unless options[:bare] || to.nil? || to=='-'
    warn "Unpacked with #{file.errors.count} errors" if options[:warn] && file.errors > 0
  ensure
    file.close
  end
end