#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    class Decoded < Bun::File::Unpacked
      attr_accessor :content
      class << self
        def create(options={})
          descriptor = options[:descriptor]
          tape_type = options[:force] || descriptor[:tape_type]
          new(options)
        end
      end
      
      def put(to_file)
        shell = Shell.new
        shell.mkdir_p File.dirname(to_file)
        shell.write(to_file, content)
      end
    end
  end
end