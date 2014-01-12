#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# require 'dir/tmpdir'

module Bun
  class File < ::File
    class Decoded < Bun::File::Unpacked
      class << self
        def create(options={})
          descriptor = options[:descriptor]
          tape_type = options[:force] || descriptor[:tape_type]
          new(options)
        end
        
        def build_data(input, options={})
          @data = input.delete(:content)
          @content = @data
        end
        
        def build_descriptor(input)
          @descriptor = Hashie::Mash.new(input)
          @descriptor.fields = @descriptor.keys
          @descriptor.shard_count = 1 if @descriptor.tape_type == :frozen
        end
        
        def examination(path, test)
          f = open(path)
          f.examination(test)
        end
    
        # Output the ASCII content of a file
        def bake(path, to=nil, options={})
          # return unless unpacked?(path)
          open(path, options) do |files|
            unless files.is_a?(Hash)
              files = {nil=>files}
            end
            files.each do |key, f|
              path = key ? File.join(to, File.basename(key)) : to
              f.descriptor.tape = options[:tape] if options[:tape]
              f.bake(path)
            end
          end
        end
        
        def open(fname, options={}, &blk)
          if File.file_grade(fname) != :decoded
            if options[:promote]
              paths = super(fname, options) do |f|
                # This could return more than one file; how does that work?
                parts = f.decode(nil, options.merge(expand: true))
                if parts.size == 1
                  t = Tempfile.new('promoted_to_decoded_')
                  t.write(parts.values.first)
                  t.close
                  options[:expand] ? {parts.values.first=>t.path} : t.path
                else
                  raise Bun::File::CantExpandError, "Frozen file without :expand option" unless options[:expand]
                  t = Dir.mktmpdir("promoted_to_decoded_")
                  shell = Shell.new
                  parts.map do |part, content|
                    path = File.join(t, part)
                    shell.write(path, content)
                    path
                  end
                end
              end
              files = paths.map {|path| [path, File::Decoded.open(path, options)] }
                           .inject({}) {|hsh, pair| key,value=pair; hsh[key] = value; hsh }
              yield(files) if block_given?
              files
            else
              raise BadFileGrade, "#{fname} is not a decoded file"
            end
          else
            # Ooh, this smells
            super(fname, options.merge(force: true), &blk)
          end
        end
      end
      
      def bake(to=nil)
        shell = Shell.new
        shell.mkdir_p File.dirname(to) if to && to!='-'
        shell.write to, data
        data
      end

      def examination(test)
        data.examination(test)
      end
      
      def decoded_text(options={})
        data
      end
    end
  end
end