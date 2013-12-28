#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "unpack FILE [TO]", "Unpack a tape (Not frozen files -- use freezer subcommands for that)"
option "bare",    :aliases=>"-b", :type=>"boolean", :desc=>"Do not create an index entry for the unpacked tape"
option "delete",  :aliases=>'-d', :type=>'boolean', :desc=>"Keep deleted lines"
option "inspect", :aliases=>'-i', :type=>'boolean', :desc=>"Display long format details for each line"
option "warn",    :aliases=>'-w', :type=>'boolean', :desc=>"Warn if there are decoding errors"
# TODO combine with other forms of read (e.g. thaw)
# TODO rename bun read
def unpack(file, to=nil)
  at = File.dirname(file)
  tape_name = File.basename(file)
  # TODO Is the Archive object even necessary here?
  archive = Archive.new(at, options)
  tape = archive.open(tape_name)
  stop "!Can't unpack #{tape_name}. It isn't a text file" unless tape.file_type == :text
  begin
    tape.extract(to, options)
    warn "Unpacked with #{tape.errors.count} errors" if options[:warn] && tape.errors > 0
  ensure
    tape.close
  end
end