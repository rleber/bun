#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "compact LIBRARY [TO]", "Remove redundant files from library"
option 'collapse', :aliases=>'-c', :type=>'boolean', :desc=>"Collapse levels if there's only one file in them", 
                   :default=>true
option 'dryrun',   :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually reorganize"
def compact(from, to=nil)
  @dryrun = options[:dryrun]
  @trace = options[:trace]
  if to
    Library.new(:at=>from).cp(:from=>".", :to=>nil, :recursive=>true)
    at = to
  else
    at = from
  end
  library = Library.new(:at=>options[:at])
  library.compact(options)
end