#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Check if string is all readable characters

class String
  class Examination
    class File < String::Examination::Base

      def self.description
        "File path of file"
      end

      def titles
        %w{File}
      end

      def initialize(*args)
        super(*args)
      end
      
      def analysis
        ::File.expand_path(file.descriptor.tape_path)
      end
    end
  end
end
