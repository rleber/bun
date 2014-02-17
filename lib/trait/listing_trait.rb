#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Check: does file appear to be a print listing?

require 'lib/trait/boolean'

class String
  class Trait
    class Listing < Boolean
      def self.description
        "Does file appear to be a print listing?"
      end

      def trait(name, options={})
        examiner = String::Trait.create(name, options)
        examiner.attach(:file, self.file)
        examiner.attach(:string, self.string)
        unwrap(examiner.value)
      end
      
      def test
        ov = trait(:overstruck)
        leg = trait(:legibility)
        roff = trait(:roff)
        ov && (leg >= 0.9) && !roff
      end
    end
  end
end
