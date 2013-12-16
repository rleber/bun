#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

desc "rm HOARD [HOARD...]", "Remove hoards from archive"
option 'at',        :aliases=>'-a', :type=>'string',  :desc=>'Archive path'
option 'recursive', :aliases=>'-r', :type=>'boolean', :desc=>'Recursively remove (a directory)'
def rm(*args)
  from_archive = Library.new(:at=>options[:at])
  begin
    from_archive.rm(:hoards=>args, :recursive=>options[:recursive])
  rescue Bun::Archive::NonRecursiveRemoveDirectory => e
    abort e.to_s
  end
end