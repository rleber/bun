#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "unpack FILE [TO]", "Read in a packed Bun file and translate to a flat YAML format"
option "fix",     :aliases=>'-F', :type=>'boolean', :desc=>"Attempt to repair errors"
option "force",   :aliases=>'-f', :type=>'boolean', :desc=>"Overwrite existing files"
option "flatten", :aliases=>'-n', :type=>'boolean', :desc=>"Flatten out subdirectories"
option "quiet",   :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
option "tape",    :aliases=>'-t', :type=>'string',  :desc=>"Supply tape name (use with input from STDIN)"
def unpack(file, to='-')
  check_for_unknown_options(file, to)
  if !options[:force] && File.exists?(to)
    if options[:quiet]
      stop
    else
      stop "!Skipping unpack: #{to} already exists"
    end
  end
  case g=File.format(file)
  when :packed
    begin
      File.unpack(file, to, options)
    rescue Bun::File::BadBlockError => e 
      stop "!Found bad BCW block: #{e}. Use --fix to override"
    rescue Bun::Data::BadTime => e
      stop "!File contains a bad time field: #{e}. Use --fix to override"
    end
  when :unpacked
    case to
    when nil,'-'
      system(['cat',file].shelljoin)
    else
      system(['cp','-f',file,to].shelljoin)
    end
  else
    if options[:quiet]
      stop
    else
      stop "!Can't unpack file. It is already #{g}"
    end
  end
end