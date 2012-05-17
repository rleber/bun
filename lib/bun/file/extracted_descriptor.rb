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
        attr_accessor :extracted
        attr_accessor :file_size
        attr_accessor :file_type
        attr_accessor :location
        attr_accessor :location_path
        attr_accessor :original_location
        attr_accessor :original_location_path
        attr_accessor :owner
        attr_accessor :path
        attr_accessor :size
        attr_accessor :specification
        attr_accessor :updated

      end
    end
  end
end