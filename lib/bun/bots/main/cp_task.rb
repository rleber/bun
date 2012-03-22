#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "cp TAPE [DESTINATION]", "Copy a file"
# TODO Refactor :archive as a global option?
option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
def cp(tape, dest = nil)
  directory = options[:archive] || Archive.location
  from_archive = Archive.new(:location=>directory)
  unless dest.nil? || dest == '-'
    dest = '.' if dest == ''
    dest = File.join(dest, File.basename(tape)) if File.directory?(dest)
  end

  from_archive.open(tape) do |f|
    Shell.new(:quiet=>true).write dest, f.read, :mode=>'w:ascii-8bit'
  end
  
  unless dest.nil? || dest == '-'
    # Copy index entry, too
    to_dir = File.dirname(dest)
    to_archive = Archive.new(:location=>to_dir, :directory=>'')
    descriptor = from_archive.descriptor(tape)
    descriptor.tape_name = File.basename(dest)
    descriptor.tape_path = File.expand_path(dest)
    to_archive.update_index(descriptor, :descriptor=>descriptor, :save=>true)
  end
end