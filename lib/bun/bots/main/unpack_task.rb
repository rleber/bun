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
  stop "!Can't unpack #{file_name}. It isn't a text file" unless file.file_type == :text
  begin
    file.extract(to, options)
    warn "Unpacked with #{file.errors.count} errors" if options[:warn] && file.errors > 0
  ensure
    file.close
  end
end