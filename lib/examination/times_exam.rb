#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Extract 'last updated' times

require 'lib/examination/character_class'

class String
  class Examination
    class Times < String::Examination::StatHash
       
      def self.description
        "Extract 'last updated' times"
      end
      
      def analysis
        file_time = file.descriptor.file_time
        catalog_time = file.descriptor.catalog_time
        shard_time = file.descriptor.shard_time
        earliest_time = [file_time, catalog_time, shard_time].compact.min
        {
          file_time:     file_time,
          shard_time:    shard_time,
          catalog_time:  catalog_time,
          earliest_time: earliest_time
        }
      end
      
      def format_time(field)
        return 'nil' unless field
        "#{field.to_s}"
      end
      
      def format_file_time(row)
        format_time(row[:file_time])
      end
      
      def format_catalog_time(row)
        format_time(row[:catalog_time])
      end
      
      def format_earliest_time(row)
        format_time(row[:earliest_time])
      end
      
      def fields
        [:file_time, :shard_time, :catalog_time, :earliest_time]
      end
    end
  end
end
