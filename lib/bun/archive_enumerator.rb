#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

module Bun
  class Archive
    class Enumerator < ::Enumerator
      attr_reader :archive
      
      def initialize(archive, *args, &blk)
        @archive = archive
        if block_given?
          super(*args, &blk)
        else
          super(*args) do |yielder|
            @archive.tapes.each do |tape| 
              yielder << tape
            end
          end
        end
      end
      
      def glob(*pat, &blk)
        regexes = pat.flatten.map {|pat| Bun.convert_glob(pat) }
        enum = Enumerator.new(@archive) do |yielder|
          self.select do |fname|
            # TODO Refactor with any?
            matched = false
            regexes.each do |regex|
              if fname =~ regex
                matched = true
                break
              end
            end
            yielder << fname if matched
          end
        end
        if block_given?
          enum.each(&blk)
        else
          enum
        end
      end
      
      def with_files(options={}, &blk)
        enum = ::Enumerator.new do |yielder|
          loop do
            fname = self.next
            f = @archive.open(fname, options)
            yielder << [fname, f]
          end
        end
        if block_given?
          enum.each(&blk)
        else
          enum
        end
      end
    
      def files(options={}, &blk)
        enum = ::Enumerator.new do |yielder|
          with_files(options).each do |fname, file|
            yielder << file
          end
        end
        if block_given?
          enum.each(&blk)
        else
          enum
        end
      end
  
    end
  end
end