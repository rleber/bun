#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Check if string is all readable characters

class String
  class Trait
    class Fields < String::Trait::Base

      def self.description
        "List fields of the file"
      end

      def initialize(*args)
        super(*args)
      end
      
      def analysis
        file.descriptor.fields.sort.map {|f| f.to_sym}
      end
    end
  end
end
