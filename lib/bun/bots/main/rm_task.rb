#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

desc "rm ARCHIVE TAPE...", "Remove tapes from archive"
option 'recursive', :aliases=>'-r', :type=>'boolean', :desc=>'Recursively remove (a directory)'
def rm(at, *args)
  from_archive = Library.new(at)
  begin
    from_archive.rm(:tapes=>args, :recursive=>options[:recursive])
  rescue Bun::Archive::NonRecursiveRemoveDirectory => e
    abort e.to_s
  end
end