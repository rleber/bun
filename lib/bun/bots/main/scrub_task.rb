#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "scrub FILE", "Clean up backspaces, control characters, and tabs in a file"
option "tabs", :aliases=>'-t', :type=>'string', :desc=>"Set tab stops"

COLUMN_WIDTH = 60
FORMFEED = %q{"\n" + "-"*COLUMN_WIDTH + "\n"}
VERTICALTAB = %q{"\n"}

def scrub(file)
  check_for_unknown_options(file)
  tabs = options[:tabs] || COLUMN_WIDTH+20
  formfeed = eval(FORMFEED)
  verticaltab = eval(VERTICALTAB)
  text = File.read(file)
  text.gsub!(/_\x8/,'') # Remove underscores
  text.gsub!(/(.)(?:\x8\1)+/,'\1') # Remove bolding
  text.gsub!(/\xC/, formfeed) # Remove form feeds
  text.gsub!(/\xB/, verticaltab) # Remove vertical tabs
  text.gsub!(/[[:cntrl:]&&[^\n\x8]]/,'') # Remove other control characters
  t = Tempfile.new('scrub')
  t.write(text)
  t.close
  system("cat #{t.path} | expand -t #{tabs}")
end