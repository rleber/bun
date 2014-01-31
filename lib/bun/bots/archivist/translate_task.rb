#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "translate [OPTIONS] FROM TO", "Process an archive, start to finish"
option "catalog",  :aliases=>'-c', :type=>'string',   :desc=>"Location of the catalog listing"
option 'flatten', :aliases=>'-f', :type=>'boolean',   :desc=>"Flatten out intermediate /ar99 directories"
option "links",    :aliases=>'-l', :type=>'string',   :desc=>"Prefix for symlinks"
option "quiet",    :aliases=>'-q', :type=>'boolean',  :desc=>"Don't announce each step of the process"
option "source",   :aliases=>'-S', :type=>'string',   :desc=>"Location of the original archive"
option "steps",    :aliases=>'-s', :type=>'string',   :desc=>"What steps to perform?", :default=>'all'
option "strict",   :aliases=>'-C', :type=>'boolean',  :desc=>"Only unpack files of the form ar999.9999"
option "tests",    :aliases=>'-T', :type=>'boolean',  :desc=>"Rebuild the test cases for this software"
option "to",       :aliases=>'-t', :type=>'string',   :desc=>"Directory to contain the output archives"
option "usage",    :aliases=>'-u', :type=>'boolean',  :desc=>"List the steps in the translation process"

DESC_TEXT = <<-EOT
Process an archive of Honeywell binary backup tapes, from start to finish. \\
There are several steps to this process. They are, in order:
    Steps:
    pull                      Pull files from the original archive
    unpack                    Unpack the files (from Honeywell binary format)
    catalog                   Catalog the files (using a catalog file)
    decode                    Decode the files
    compress                  Compress the decoded files
    bake                      Bake the files (i.e. remove metadata)
    tests                     Rebuild the test cases for the bun software
    all                       Run all the steps

This command takes a list of steps, which it will execute in the appropriate order. \\
Some convenience abbreviations are allowed:
    not-xxx (or not_xxx or notxxx)    Exclude this step
    all  (or .. or ...)               Include all steps
    ..xxx                             All steps leading up to xxx
    ...xxx                            All steps up to (but not including) xxx
    xxx.. (or xxx...)                 All steps beginning with xxx
    xxx..yyy                          Steps xxx to yyy
    xxx...yyy                         Steps xxx to the step before yyy
EOT
long_desc DESC_TEXT.freeze_for_thor
def translate(from, to)
  check_for_unknown_options(from, to)
  if options[:usage]
    puts Bun::Archive.translate_steps
    exit
  end
  Bun::Archive.translate(from, to, options)
rescue Archive::InvalidStep => e
  stop "!#{e}"
rescue Archive::MissingCatalog
  stop "!Must specify --catalog"
end