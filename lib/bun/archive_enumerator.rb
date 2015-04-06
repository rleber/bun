#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

module Bun
  class Archive < Collection
    class Enumerator < Collection::Enumerator
      
      def folders(&blk)
        enum = self.class.new(@collection) do |yielder|
          all.with_path do |fname, path|
            if ::File.directory?(path)
              yielder << fname
            else
              descriptor = @collection.descriptor(fname)
              yielder << fname if descriptor.type == :frozen
            end
          end
        end
        if block_given?
          enum.each(&blk)
        else
          enum
        end
      end
      
      def items(&blk)
        enum = self.class.new(@collection) do |yielder|
          all.with_path do |fname, path|
            if ::File.file?(path)
              yielder << fname
              descriptor = @collection.descriptor(fname)
              if descriptor.type == :frozen
                descriptor.shard_names.each do |shard_name|
                  yielder << "#{fname}[#{shard_name}]"
                end
              end
            end
          end
        end
        if block_given?
          enum.each(&blk)
        else
          enum
        end
      end

      
      def fragments(&blk)
        enum = self.class.new(@collection) do |yielder|
          all.with_path do |fname, path|
            if ::File.file?(path)
              descriptor = @collection.descriptor(fname)
              if descriptor.type == :frozen
                descriptor.shard_names.each do |shard_name|
                  yielder << "#{fname}[#{shard_name}]"
                end
              else
                yielder << fname
              end
            end
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