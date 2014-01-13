#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO Extract multiple files
# TODO Extract multiple shards
desc "decode FILE [TO]", "Uncompress a frozen Honeywell file"
option 'asis',    :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to unpack file first"
option "delete",  :aliases=>'-d', :type=>'boolean', :desc=>"Keep deleted lines (only with text files)"
option "expand",  :aliases=>'-e', :type=>'boolean', :desc=>"Expand freezer archives into multiple files"
option "inspect", :aliases=>'-i', :type=>'boolean', :desc=>"Display long format details for each line (only with text files)"
option "shard",   :aliases=>'-s', :type=>'string',  :desc=>"Select shards with this pattern (only with frozen files)"
option "warn",    :aliases=>"-w", :type=>"boolean", :desc=>"Warn if bad data is found"
long_desc <<-EOT
FILE may have some special formats: '+-nnn' (where nnn is an integer) denotes file number nnn. '-nnn' denotes the nnnth
file from the end of the archive. Anything else denotes the name of a file. A backslash character is ignored at the
beginning of a file name, so that '\\+1' refers to a file named '+1', whereas '+1' refers to the first file in the archive,
whatever its name.
EOT
def decode(file_name, out=nil)
  check_for_unknown_options(file_name, out)
  shard = options[:shard]
  if file_name =~ /(^.*)\[(.*)\]$/ # Has a shard specifier
    file_name = $1
    shard = $2
  end
  out ||= '-'
  # TODO The following should be a simple primitive operation
  case File.file_grade(file_name)
  when :baked
    stop "!Can't decode file. It is already baked"
  when :decoded
    case out
    when nil, '-'
      system(['cat',file_name].shelljoin)
    else
      system(['cp','-f',file_name,out].shelljoin) if out
    end
  else
    File::Unpacked.open(file_name, :promote=>!options[:asis]) do |file|
      begin
        file.decode(out, options.merge(:shard=>shard))
      rescue Bun::File::CantExpandError
        stop "!Can't expand frozen archive. Provide --shard option or --expand and directory name"
      end
      warn "Decoded with #{file.errors.count} decoding errors" if options[:warn] && file.errors > 0
    end
  end
end