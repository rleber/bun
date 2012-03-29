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
            @archive.locations.each do |location| 
              yielder << location
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
      
      def with_paths(&blk)
        enum = ::Enumerator.new do |yielder|
          loop do
            fname = self.next
            path = @archive.expand_path(fname)
            yielder << [fname, path]
          end
        end
        if block_given?
          enum.each(&blk)
        else
          enum
        end
      end
      
      def directories(&blk)
        enum = ::Enumerator.new do |yielder|
          with_paths.each do |fname, path|
            yielder << file if ::File.directory?(path)
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
          with_paths.each do |fname, path|
            yielder << [fname, @archive.open(fname, &blk)] unless ::File.directory?(path)
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