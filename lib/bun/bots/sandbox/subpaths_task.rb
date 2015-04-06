#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "subpaths", "Show subpaths in files"
def subpaths(*files)
  files.each do |file|
    f = File::Packed.open(file)
    subpath = f.descriptor.subpath
    path = f.descriptor.path
    type = f.type
    f.close
    puts "#{file}: #{type} #{subpath} => #{path}"
  end
end
