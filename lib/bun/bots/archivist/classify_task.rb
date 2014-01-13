#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

DEFAULT_THRESHOLD = 20
desc "classify FROM [TO]", "Classify files based on whether they're clean or not, etc."
option 'dryrun',    :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually classify"
option "link",      :aliases=>"-l", :type=>"boolean", :desc=>"Symlink files to clean/dirty directories (instead of copy)"
option 'quiet',     :aliases=>'-d', :type=>'boolean', :desc=>"Quiet mode"
option 'test',      :aliases=>'-t', :type=>'string',  
                    :desc=>"What test? See bun help classify for options",
                    :default=>'clean'
long_desc <<-EOT
Classifies all the files in the library, based on whether they pass certain tests.

If TO is specified, files are linked (or copied) into separate directories, depending
on the outcome of the tests. For instance, if the "clean" test is specified (--test clean),
the files are classified into two directories: TO/clean and TO/dirty.
EOT
def classify(from, to=nil)
  check_for_unknown_options(from, to)
  Archive.classify(from, to, options)
end