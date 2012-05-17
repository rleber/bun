#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    class Extracted < Bun::File
      class << self
        def open(fname, options, &blk)
          f = send(:new, options.merge(:location_path=>fname))
          if options[:library]
            descriptor_hash = options[:library].descriptor(fname, :build=>false)
            f.descriptor = File::Descriptor::Extracted.from_hash(self, descriptor_hash)
          end
          if block_given?
            begin
              yield f
            ensure
              f.close
            end
          end
          f
        end
      end
    end
  end
end