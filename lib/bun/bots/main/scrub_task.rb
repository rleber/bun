#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "scrub FILE", "Clean up backspaces, control characters, and tabs in a file"
option "tabs", :aliases=>'-t', :type=>'string', :desc=>"Set tab stops"

COLUMN_WIDTH = 60
FORMFEED = %q{"\n" + "-"*COLUMN_WIDTH + "\n"}
VERTICALTAB = %q{"\n"}

def scrub(file)
  check_for_unknown_options(file)
  formfeed = eval(FORMFEED)
  verticaltab = eval(VERTICALTAB)
  text = File.read(file)
  scrubbed_text = text.scrub(:column_width=>COLUMN_WIDTH, :form_feed=>formfeed, :vertical_tab=>verticaltab)
  puts scrubbed_text
end