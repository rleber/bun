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
      end
      
      def put(to_file)
        shell = Shell.new
        shell.mkdir_p File.dirname(to_file)
        shell.write(to_file, data)
      end

      def check(test)
        data.check(test)
      end
    end
  end
end