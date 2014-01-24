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
        time = file.descriptor.time
        catalog_time = file.descriptor.catalog_time
        shard_time = file.descriptor.shard_time
        earliest_time = [time, catalog_time, shard_time].compact.min
        {
          time:     time,
          shard_time:    shard_time,
          catalog_time:  catalog_time,
          earliest_time: earliest_time
        }
      end
      
      def format_time_value(field)
        return 'nil' unless field
        field.to_s
      end
      
      def format_time(row)
        format_time_value(row[:time])
      end
      
      def format_shard_time(row)
        format_time_value(row[:shard_time])
      end

      def format_catalog_time(row)
        format_time_value(row[:catalog_time])
      end
      
      def format_earliest_time(row)
        format_time_value(row[:earliest_time])
      end
      
      def fields
        [:time, :shard_time, :catalog_time, :earliest_time]
      end

      def titles
        ["File Time", "Shard Time", "Catalog Time", "Earliest Time"]
      end
    end
  end
end
