#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

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
          open(path, options) do |f|
            f.descriptor.tape = options[:tape] if options[:tape]
            f.bake(to)
          end
        end
        
        def open(fname, options={}, &blk)
          # debug "fname: #{fname}, options: #{options.inspect}\n  caller: #{caller.first}"
          if File.file_grade(fname) != :decoded
            if options[:promote]
              t = Tempfile.new('promoted_to_decoded_')
              t.close
              super(fname, options) do |f|
                if f.tape_type == :frozen
                  ::File.open(t.path, 'w') do |outfile|
                    f.shard_count.times do |i|
                      # TODO: insert shard names, allow overriding (or prevention) of headers
                      outfile.puts "----- Shard #{i} -----"
                      outfile.write f.to_decoded_yaml(options.merge(shard: i))
                    end
                  end
                else
                  f.decode(t.path, options)
                end
              end
              # puts "Decoded file:" # debug
              # system("cat #{t.path} | more")
              f = File::Decoded.open(t.path, options, &blk)
              f
            else
              raise BadFileGrade, "#{fname} is not a decoded file"
            end
          else
            # Ooh, this smells
            super(fname, options.merge(force: true))
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