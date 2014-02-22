#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "subpaths", "Show subpaths in files"
def subpaths(*files)
  files.each do |file|
    f = File::Packed.open(file)
    subpath = f.descriptor.subpath
    path = f.descriptor.path
    f.close
    puts "#{file}: #{subpath} => #{path}"
  end
end
