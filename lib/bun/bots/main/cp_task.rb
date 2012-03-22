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
  archive.open(tape) {|f| Shell.new(:quiet=>true).write dest, f.read }
end