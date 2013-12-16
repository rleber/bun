#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "unpack HOARD [TO]", "Unpack a hoard (Not frozen files -- use freezer subcommands for that)"
option 'at',      :aliases=>'-a', :type=>'string',  :desc=>'Archive path'
option "bare",    :aliases=>"-b", :type=>"boolean", :desc=>"Do not create an index entry for the unpacked hoard"
option "delete",  :aliases=>'-d', :type=>'boolean', :desc=>"Keep deleted lines"
option "inspect", :aliases=>'-i', :type=>'boolean', :desc=>"Display long format details for each line"
option "warn",    :aliases=>'-w', :type=>'boolean', :desc=>"Warn if there are decoding errors"
# TODO combine with other forms of read (e.g. thaw)
# TODO rename bun read
def unpack(hoard_name, to=nil)
  archive = Archive.new(options)
  hoard = archive.open(hoard_name)
  stop "!Can't unpack #{hoard_name}. It isn't a text file" unless hoard.file_type == :text
  begin
    hoard.extract(to, options)
    warn "Unpacked with #{hoard.errors.count} errors" if options[:warn] && hoard.errors > 0
  ensure
    hoard.close
  end
end