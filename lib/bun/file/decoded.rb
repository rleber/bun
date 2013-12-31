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
        
        def check(path, test)
          f = open(path)
          f.check(test)
        end
    
        # Output the ASCII content of a file
        def bake(path, to=nil, options={})
          # return unless unpacked?(path)
          open(path) do |f|
            f.descriptor.tape = options[:tape] if options[:tape]
            f.bake(to)
          end
        end
      end
      
      def bake(to=nil)
        shell = Shell.new
        shell.mkdir_p File.dirname(to) if to && to!='-'
        shell.write to, data
        data
      end

      def check(test)
        data.check(test)
      end
    end
  end
end