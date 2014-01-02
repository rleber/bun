#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'date'

module Bun

  class File < ::File
    class UnknownFileType < RuntimeError; end
    class UnexpectedTapeType < RuntimeError; end
    class InvalidInput < RuntimeError; end
    
    class Unpacked < Bun::File
      class << self
        
        def read_information(fname)
          input = begin
            YAML.load(Bun::File.read(fname))
          rescue => e
            raise InvalidInput, "Error reading #{fname}: #{e}"
          end
          raise InvalidInput, "Expected #{fname} to be a Hash, not a #{input.class}" \
            unless input.is_a?(Hash)
          input
        end
        
        def build_data(input, options={})
          @data = input.delete(:content)
          @content = Data.new(
            :data=>@data, 
            :archive=>options[:archive], 
            :tape=>options[:tape], 
            :tape_path=>options[:fname],
          )
        end
        
        def build_descriptor(input)
          @descriptor = Descriptor::Base.from_hash(@content,input)
        end
        
        def forced_open(fname, options={}, &blk)
          options[:fname] = fname
          input = read_information(fname)
          build_data(input, options)
          build_descriptor(input)
          options.merge!(:data=>@data, :descriptor=>@descriptor, :tape_path=>options[:fname])
          if options[:type] && @descriptor[:tape_type]!=options[:type]
            msg = "Expected file #{fname} to be a #{options[:type]} file, not a #{descriptor[:tape_type]} file"
            if options[:graceful]
              stop "!#{msg}"
            else
              raise UnexpectedTapeType, msg
            end
          end
          file = create(options)
          if block_given?
            begin
              yield(file)
            ensure
              file.close
            end
          else
            file
          end
        end

        # TODO -- Generalize this, and move it to File
        def open(fname, options={}, &blk)
          if options[:force]
            forced_open(fname, options, &blk)
          elsif (grade = File.file_grade(fname)) != :unpacked
            if options[:promote]
              if File.file_grade_level(grade) < File.file_grade_level(:unpacked)
                t = Tempfile.new('promote_to_unpacked')
                t.close
                super(fname, options) {|f| f.decode(t.path, options)}
                open(t.path, options, &blk)
              else
                raise BadFileGrade, "#{fname} can't be converted to unpacked"
              end
            else
              raise BadFileGrade, "#{fname} is not a decode file"
            end
          else
            forced_open(fname, options, &blk)
          end
        end
        
        def create(options={})
          descriptor = options[:descriptor]
          tape_type = options[:force] || descriptor[:tape_type]
          case tape_type
          when :text
            File::Unpacked::Text.new(options)
          when :frozen
            File::Unpacked::Frozen.new(options)
          else
            if options[:strict]
              raise UnknownFileType,"!Unknown file type: #{descriptor.tape_type.inspect}"
            else
              File::Unpacked::Text.new(options)
            end
          end
        end
        
        def clean_file?(fname)
          open(fname) do |f|
            File.clean?(f.text)
          end
        end
        
        def mark(fname, tag_hash, to=nil)
          to ||= fname
          File.open(fname) do |f|
            tag_hash.each do |tag, value|
              f.mark tag, value
            end
            f.write(to)
          end
        end
      end

      attr_reader :data
      attr_reader :descriptor

      # Create a new File
      # Options:
      #   :data        A File::Data object containing the file's data
      #   :archive     The archive containing the file
      #   :tape        The tape name of the file
      #   :tape_path   The path name of the file
      #   :descriptor  The descriptor for the file
       def initialize(options={})
        @header = options[:header]
        @descriptor = options[:descriptor]
        @data = options[:data]
        # self.words = self.class.get_words(options[:limit], options)
        super
      end

      def header?
        @header
      end
      
      def tape_type
        descriptor.tape_type
      end
      
      def file_time
        descriptor.file_time
      end
      
      BUN_IDENTIFIER = "Bun"
      
      def to_hash(options={})
        # Note: This is set up to include fields in a particular order:
        #  1. :identifier
        #  2. Other fields, in sorted key order:
        #    a. Descriptor fields (except :data), in sorted key order
        #    b. :digest
        #    c. All other fields specified in options
        #  6. :shards
        #  7. :content
        content = options.delete(:content)
        content ||= data.data
        fields = descriptor.to_hash
        fields.delete(:data)
        fields.delete(:shards)
        file_grade = options.delete(:file_grade)
        fields[:file_grade] = file_grade || :unpacked
        fields[:digest]  = content.digest
        if tape_type == :frozen
          shards = shard_descriptors.map do |d|
            {
              :name      => d.name,
              :file_time => d.file_time,
              :blocks    => d.blocks,
              :start     => d.start,
              :size      => d[:size], # Need to do it this way, because d.size is the builtin
            }
          end
        else
          options.delete(:shard)
          options.delete(:shards)
        end
        fields.merge!(options)
        hash = {identifier: BUN_IDENTIFIER}.merge(fields.symbolized_keys.sorted)
        hash[:shards] = shards if shards
        hash[:content] = content
        hash
      end
      
      def to_yaml(options={})
        to_hash(options).to_yaml
      end
      
      def write(to=nil)
        to ||= tape_path
        shell = Shell.new
        output = to_yaml
        shell.write to, to_yaml
        output
      end

      def unpack
        self
      end
      
      # Subclasses must define decoded_text
      def decoded_text(options={})
        raise RuntimeError, "#{self.class} does not define decoded_text"
      end
      
      def to_decoded_hash(options={})
        options = options.merge(
                    content: decoded_text(options), 
                    file_grade: :decoded,
                    decode_time: Time.now,
                    decoded_by:  Bun.expanded_version
                  )
        to_hash(options)
      end
      
      def to_decoded_yaml(options={})
        to_decoded_hash(options).to_yaml
      end

      def decode(to, options={})
        Shell.new.write(to,to_decoded_yaml(options))
      end

      def method_missing(meth, *args, &blk)
        data.send(meth, *args, &blk)
      rescue NoMethodError => e
        raise NoMethodError, %{"#{self.class}##{meth} method not defined:\n  Raised #{e} at:\n#{e.backtrace.map{|c| '    ' + c}.join("\n")}}
      end
    end
  end
end
