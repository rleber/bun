#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

module Bun
  class Catalog
    include Enumerable
    
    class Entry
      attr_reader :tape, :date, :file
      def initialize(tape, date, file)
        @tape = tape
        @date = date
        @file = file
      end
    end
    
    attr_reader :at, :entries
    
    def initialize(cp, options={})
      cp = ::File.expand_path(cp)
      @at = cp
      content = cp && Bun.readfile(cp, :encoding=>'us-ascii')
      @entries = if content
        content.split("\n").map do |line|
          words = line.strip.split(/\s+/)
          raise RuntimeError, "Bad line in index file: #{line.inspect}" unless words.size == 3
          # TODO Create a full timestamp (set to midnight)
          date = begin
            Date.strptime(words[1], "%y%m%d")
          rescue
            raise RuntimeError, "Bad date #{words[1].inspect} in index file at #{line.inspect}"
          end
          Entry.new(words[0], date,words[2])
        end
      else
        []
      end
    end
    
    def time_for(tape)
      entry = entries.find {|spec| spec.tape == tape }
      entry && entry.date.local_date_to_local_time
    end
  end
end