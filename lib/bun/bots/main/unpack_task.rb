#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "unpack FILE [TO]", "Read in a packed Bun file and translate to a flat YAML format"
option "tape", :aliases=>'-t', :type=>'string',  :desc=>"Supply tape name (use with input from STDIN)"
def unpack(file, to='-')
  check_for_unknown_options(file, to)
  case g=File.format(file)
  when :packed
    File.unpack(file, to, options)
  when :unpacked
    case to
    when nil,'-'
      system(['cat',file].shelljoin)
    else
      system(['cp','-f',file,to].shelljoin)
    end
  else
    stop "!Can't unpack file. It is already #{g}"
  end
end