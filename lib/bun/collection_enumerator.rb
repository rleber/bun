#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

module Bun
  class Collection
    class Enumerator < ::Enumerator
      attr_reader :collection
      
      def initialize(collection, *args, &blk)
        @collection = collection
        if block_given?
          super(*args, &blk)
        else
          super(*args) do |yielder|
            @collection.locations.each do |location| 
              yielder << location
            end
          end
        end
      end
      
      # TODO glob should handle '**/xx' patterns
      def glob(*pat, &blk)
        regexes = pat.flatten.map {|pat| Bun.convert_glob(pat) }
        enum = self.class.new(@collection) do |yielder|
          self.each do |fname|
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
      
      def with_path(&blk)
        enum = ::Enumerator.new do |yielder|
          loop do
            fname = self.next
            path = @collection.expand_path(fname)
            yielder << [fname, path]
          end
        end
        if block_given?
          enum.each(&blk)
        else
          enum
        end
      end
      
      def with_depth(&blk)
        enum = ::Enumerator.new do |yielder|
          loop do
            fname = self.next
            depth = fname== '.' ? 0 : fname.split("/").size
            yielder << [fname, depth]
          end
        end
        if block_given?
          enum.each(&blk)
        else
          enum
        end
      end
      
      def depth_first(&blk)
        sorted_enum = self.with_depth.to_a.sort_by{|name, depth| [-depth, name]}.map{|name, depth| name}.to_enum
        enum = self.class.new(@collection) do |yielder|
          loop do
            yielder << sorted_enum.next
          end
        end
        if block_given?
          enum.each(&blk)
        else
          enum
        end
      end
      
      def all(&blk)
        collection = Dir.glob("#{@collection.at}/**/*").map{|f| @collection.relative_path(f) }
        collection.unshift '.'
        collection = collection.to_enum
        enum = self.class.new(@collection) do |yielder|
          loop do
            yielder << collection.next
          end
        end
        if block_given?
          enum.each(&blk)
        else
          enum
        end
      end
      
      def directories(&blk)
        enum = self.class.new(@collection) do |yielder|
          all.with_path do |fname, path|
            yielder << fname if ::File.directory?(path)
          end
        end
        if block_given?
          enum.each(&blk)
        else
          enum
        end
      end
      
      alias_method :folders, :directories
      
      def leaves(&blk)
        enum = self.class.new(@collection) do |yielder|
          all.with_path do |fname, path|
            yielder << fname unless ::File.directory?(path)
          end
        end
        if block_given?
          enum.each(&blk)
        else
          enum
        end
      end
      
      alias_method :fragments, :leaves
      alias_method :items, :leaves
      
      def with_files(options={}, &blk)
        enum = ::Enumerator.new do |yielder|
          with_path.each do |fname, path|
            yielder << [fname, @collection.open(fname, &blk)] unless ::File.directory?(path)
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