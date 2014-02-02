#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

module Bun
  # Represents file catalog
  # Lazy implementation: only reads enough of the catalog to determine if the requested
  # entry is in it. This speeds things up on very large catalogs.
  class Catalog
    include Enumerable
    
    class Entry
      attr_reader :tape, :date, :file, :incomplete
      def initialize(tape, date, file, incomplete)
        @tape = tape
        @date = date
        @file = file
        @incomplete = incomplete
      end

      def time
        @date.local_date_to_local_time
      end
    end
    
    attr_reader :at, :entries, :dictionary, :file
    attr_accessor :sorted
    
    def initialize(cp, options={})
      cp = ::File.expand_path(cp)
      @at = cp
      @file = ::File.open(cp, "r:ascii-8bit")
      @sorted = options[:sorted]==:false ? false : true # Default is that we are sorted
      content = cp && Bun.readfile(cp, :encoding=>'ascii-8bit')
      @entries = []
      @dictionary = {}
    end

    def lineno
      @file.lineno
    end

    def eof?
      @file.eof?
    end

    def read_entry
      line = @file.gets
      entry = line && decode_entry(line, lineno)
      if entry
        @entries << entry
        @dictionary[entry.tape] = entry
      end
      entry
    end

    def decode_entry(line, line_number=nil)
      line = $1 if (incomplete = line =~ /(.*)\s+\(incomplete file\)$/)
      words = line.strip.split(/\s+/)
      raise RuntimeError, "Bad line in index file: #{line.inspect}" unless words.size == 3
      # TODO Create a full timestamp (set to midnight)
      date = begin
        Date.strptime(words[1], "%y%m%d")
      rescue
        line_spec = line_number ? " line #{line_number}:" : ''
        raise RuntimeError, "Bad date #{words[1].inspect} in catalog file at#{line_spec} #{line.inspect}"
      end
      Entry.new(words[0], date, words[2], incomplete)
    end

    def [](tape)
      tape = tape.sub(/#{DEFAULT_UNPACKED_FILE_EXTENSION}$/,'')
      dictionary[tape] || seek(tape)
    end

    # Read all the entries until you find the one we're looking for 
    def seek(tape)
      while !eof? do
        e = read_entry
        return nil unless e
        if e.tape == tape # Found it
          return e
        elsif self.sorted && e.tape > tape # Then this tape isn't in the catalog
          return nil 
        end # Otherwise, keep looking
      end
    end
    
    def time_for(tape)
      entry = self[tape]
      entry && entry.date.local_date_to_local_time
    end
  end
end