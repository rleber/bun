#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

COLUMN_WIDTH = 60

desc "scrub FILE [TO]", "Clean up backspaces, control characters, and tabs in a file"
option "ff",    :aliases=>'-f', :type=>'string',  :desc=>"Replace form feeds with this"
option "tabs",  :aliases=>'-t', :type=>'string',  :desc=>"Set tab stops"
option "vtab",  :aliases=>'-V', :type=>'string',  :desc=>"Replace vertical tabs with this"
option "width", :aliases=>'-w', :type=>'numeric', :desc=>"Column width", :default=>COLUMN_WIDTH

FORM_FEED = %q{"\n" + "-"*column_width + "\n"}
VERTICAL_TAB = %q{"\n"}

def scrub(file, to='-')
  check_for_unknown_options(file)
  File.scrub(file, to, options)
end