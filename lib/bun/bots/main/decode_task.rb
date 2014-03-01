#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO Extract multiple files
# TODO Extract multiple shards
desc "decode FILE [TO]", "Uncompress a frozen Honeywell file"
option 'asis',    :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to unpack file first"
option "delete",  :aliases=>'-d', :type=>'boolean', :desc=>"Keep deleted lines (only with text files)"
option "force",   :aliases=>'-f', :type=>'boolean', :desc=>"Overwrite existing files"
option "expand",  :aliases=>'-e', :type=>'boolean', :desc=>"Expand freezer archives into multiple files"
option "inspect", :aliases=>'-i', :type=>'boolean', :desc=>"Display long format details for each line (only with normal files)"
option "quiet",   :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
option "shard",   :aliases=>'-S', :type=>'string',  :desc=>"Select shards with this pattern (only with frozen files)"
option "scrub",   :aliases=>'-s', :type=>'boolean', :desc=>"Remove control characters from output"
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
  file_name, shard_2 = Bun::File.get_shard(file_name)
  shard = shard_2 || shard
  out ||= '-'
  # TODO The following should be a simple primitive operation
  case File.format(file_name)
  when :baked
    if options[:quiet]
      stop
    else
      stop "!Can't decode file. It is already baked"
    end
  when :decoded
    out ||= '-'
    File::Decoded.open(file_name) {|f| f.decode(out, options)}
  else
    File::Unpacked.open(file_name, :promote=>!options[:asis]) do |file|
      begin
        file.decode(out, options.merge(:shard=>shard))
      rescue Bun::HuffmanData::BadFileContentError => e
        stop "!Bad Huffman encoded file: #{e}", quiet: options[:quiet]
      rescue Bun::HuffmanData::TreeTooDeepError => e
        stop "!Bad Huffman encoded file: #{e}", quiet: options[:quiet]
      rescue Bun::File::CantExpandError
        stop "!Can't expand frozen archive. Provide --shard option or --expand and directory name", quiet: options[:quiet]
      end
      warn %Q{Decoded with #{file.errors.count} decoding errors:\n#{file.errors.join("\n")}} if !options[:quiet] && options[:warn] && file.errors.size > 0
    end
  end
end