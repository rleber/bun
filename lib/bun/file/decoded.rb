#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    class Decoded < Bun::File::Unpacked
      class << self
        def create(options={})
          descriptor = options[:descriptor]
          tape_type = options[:force] || descriptor[:tape_type]
          new(options)
        end
        
        def build_data(input, options={})
          @data = input.delete(:content)
          @content = @data
        end
        
        def build_descriptor(input)
          @descriptor = Hashie::Mash.new(input)
        end
        
        def examination(path, test)
          f = open(path)
          f.examination(test)
        end
    
        # Output the ASCII content of a file
        def bake(path, to=nil, options={})
          # return unless unpacked?(path)
          open(path) do |f|
            f.descriptor.tape = options[:tape] if options[:tape]
            f.bake(to)
          end
        end
        
        def open(fname, options={}, &blk)
          if File.file_grade(fname) != :decoded
            if options[:promote]
              t = Tempfile.new('promote_to_decode')
              t.close
              super(fname, options) {|f| f.decode(t.path, options)}
              open(t.path, options, &blk)
            else
              raise BadFileGrade, "#{fname} is not a decoded file"
            end
          else
            super
          end
        end
      end
      
      def bake(to=nil)
        shell = Shell.new
        shell.mkdir_p File.dirname(to) if to && to!='-'
        shell.write to, data
        data
      end

      def examination(test)
        data.examination(test)
      end
    end
  end
end