#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "unpack FILE [TO]", "Unpack a tape (Not frozen files -- use freezer subcommands for that)"
option "delete",  :aliases=>'-d', :type=>'boolean', :desc=>"Keep deleted lines"
option "inspect", :aliases=>'-i', :type=>'boolean', :desc=>"Display long format details for each line"
option "warn",    :aliases=>'-w', :type=>'boolean', :desc=>"Warn if there are decoding errors"
def unpack(file_name, to=nil)
  File::Text.open(file_name, :graceful=>true) do |tape|
    tape.extract(to, options)
    warn "Unpacked with #{tape.errors.count} errors" if options[:warn] && tape.errors > 0
  end
end