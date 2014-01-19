#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Check if string is all readable characters

require 'lib/examination/array'

class String
  class Examination
    class Fields < String::Examination::Array

      def self.description
        "List fields of the file"
      end

      def initialize(*args)
        super(*args)
      end
      
      def analysis
        file.descriptor.fields.sort
      end
    end
  end
end
