#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Descriptor
      class Extracted < Base

        attr_accessor :basename
        attr_accessor :catalog_time
        attr_accessor :description
        attr_accessor :errors
        attr_accessor :decoded
        attr_accessor :file_size
        attr_accessor :tape_type
        attr_accessor :tape
        attr_accessor :tape_path
        attr_accessor :original_tape
        attr_accessor :original_tape_path
        attr_accessor :owner
        attr_accessor :path
        attr_accessor :size
        attr_accessor :specification
        attr_accessor :updated

      end
    end
  end
end