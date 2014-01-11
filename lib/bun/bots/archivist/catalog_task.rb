#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "catalog ARCHIVE [TO]", "Set file modification dates for archived files, based on catalog"
option "catalog",  :aliases=>'-c', :type=>'string',   :desc=>"Location of the catalog listing"
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually set dates"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode; do not echo filenames as they are modified"
option 'remove',  :aliases=>'-r', :type=>'boolean', :desc=>"Remove any files which are not in the catalog"
def catalog(at, to=nil)
  stop "!Missing --catalog" unless options[:catalog]
  Archive.catalog(at, to, options)
end