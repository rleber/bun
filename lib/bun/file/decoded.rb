#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# require 'dir/tmpdir'

module Bun
  class File < ::File
    class Decoded < Bun::File::Unpacked
      class << self
        def create(options={})
          descriptor = options[:descriptor]
          type = options[:force] || descriptor[:type]
          new(options)
        end
        
        def build_data(input, options={})
          @data = input.delete(:content)
          @content = @data
        end
        
        def build_descriptor(input)
          @descriptor = Hashie::Mash.new(input)
          @descriptor.fields = @descriptor.keys
          @descriptor.shard_count = 1 if @descriptor.type == :frozen
        end
        
        def trait(path, test)
          f = open(path)
          f.trait(test)
        end
    
        # Output the ASCII content of a file
        def bake(path, to=nil, options={})
          # return unless unpacked?(path)
          scrub = options.delete(:scrub)
          open(path, options) do |files|
            unless files.is_a?(Hash)
              files = {nil=>files}
            end
            files.each do |key, f|
              path = key ? File.join(to, File.basename(key)) : to
              f.descriptor.tape = options[:tape] if options[:tape]
              f.bake(path, scrub: scrub, force: options[:force], quiet: options[:quiet])
            end
          end
        end
        
        def open(fname, options={}, &blk)
          if File.format(fname) != :decoded
            if options[:promote]
              paths = super(fname, options.merge(as_class: File::Unpacked)) do |f|
                parts = f.decode(nil, options.merge(expand: true))
                raise Bun::File::CantExpandError, "Frozen file without :expand option" if parts.size >1 && !options[:expand]
                t = Dir.mktmpdir("promoted_to_decoded_")
                shell = Shell.new
                parts.map do |part, content|
                  path = File.join(t, part||'part1')
                  shell.write(path, content)
                  path
                end
              end
              files = paths.map {|path| [path, File::Decoded.open(path, options)] }
                           .inject({}) {|hsh, pair| key,value=pair; hsh[key] = value; hsh }
              return_file = options[:expand] ? files : files.values.first
              if block_given?
                yield(return_file)
              else 
                return_file
              end
            else
              raise BadFileGrade, "#{fname} is not a decoded file"
            end
          else
            # Ooh, this smells
            super(fname, options.merge(force: true), &blk)
          end
        end
      end
      
      def bake(to=nil, options={})
        shell = Shell.new
        shell.mkdir_p File.dirname(to) if to && to!='-'
        text = data
        text = data.scrub if options[:scrub]
        if !options[:force] && (to!='-' && !to.nil? && File.exists?(to))
          warn "skipping bake: #{to} already exists" unless options[:quiet]
        else
          shell.write to, text
        end
        text
      end

      # TODO DRY this up; see File::Baked, for instance
      def decode(to, options={}, &blk)
        to = yield(self, 0) if block_given? # Block overrides "to"
        shell = Shell.new
        shell.mkdir_p(File.dirname(to)) unless to.nil? || to == '-'
        text = read
        if !options[:force] && (to!='-' && !to.nil? && File.exists?(to))
          warn "skipping decode: #{to} already exists" unless options[:quiet]
        else
          shell.write(to, text) unless to.nil?
        end
        text
      end

      def trait(test)
        data.trait(test)
      end
      
      def decoded_text(options={})
        data
      end
    end
  end
end