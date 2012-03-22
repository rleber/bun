#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO Move core capability to Archive; refactor
# TODO Copy more than one file
# TODO Copy by pattern
# TODO Create mv command

desc "cp TAPE [DESTINATION]", "Copy a file"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option 'bare',    :aliases=>'-b', :type=>'boolean', :desc=>'Copy file, but not index data'
def cp(tape, dest = nil)
  directory = options[:archive] || Archive.location
  from_archive = Archive.new(:location=>directory)
  to_stdout = dest.nil? || dest == '-'
  index = !options[:bare] && !to_stdout
  unless to_stdout
    dest = '.' if dest == ''
    dest = File.join(dest, File.basename(tape)) if File.directory?(dest)
  end

  from_archive.open(tape) do |f|
    Shell.new(:quiet=>true).write dest, f.read, :mode=>'w:ascii-8bit'
  end

  if index
    # Copy index entry, too
    to_dir = File.dirname(dest)
    to_archive = Archive.new(:location=>to_dir, :directory=>'')
    descriptor = from_archive.descriptor(tape)
    descriptor.original_tape_name = tape unless descriptor.original_tape_name
    descriptor.original_tape_path = from_archive.expanded_tape_path(tape) unless descriptor.original_tape_path
    descriptor.tape_name = File.basename(dest)
    descriptor.tape_path = File.expand_path(dest)
    to_archive.update_index(:descriptor=>descriptor)
  end
end