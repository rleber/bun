#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'date'

module Bun

  class File < ::File
    class UnknownFileTypeError < RuntimeError; end
    class UnexpectedTapeTypeError < RuntimeError; end
    class InvalidInputError < RuntimeError; end
    class CantExpandError < RuntimeError; end
    
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
          options = options.merge(:data=>@data, :descriptor=>@descriptor, :tape_path=>options[:fname])
          if options[:type] && @descriptor[:tape_type]!=options[:type]
            msg = "Expected file #{fname} to be a #{options[:type]} file, not a #{descriptor[:tape_type]} file"
            # TODO Remove this option; use exception handling, instead
            if options[:graceful]
              stop "!#{msg}"
            else
              raise UnexpectedTapeTypeError, msg
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
          # debug "fname: #{fname}, options: #{options.inspect}\n  caller: #{caller.first}"
          if options[:force]
            forced_open(fname, options, &blk)
          elsif (grade = File.file_grade(fname)) != :unpacked
            if options[:promote]
              if File.file_grade_level(grade) < File.file_grade_level(:unpacked)
                t = Tempfile.new('promoted_to_unpacked_')
                t.close
                # TODO redo this:
                # super(fname, options) {|f| f.unpack(t.path, options)}
                File.unpack(fname, t.path)
                # puts "Unpacked file:" # debug
                # system("cat #{t.path} | more")
                File::Unpacked.open(t.path, options, &blk)
              else
                raise BadFileGrade, "#{fname} can't be converted to unpacked"
              end
            else
              raise BadFileGrade, "#{fname} is not an unpacked file"
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
              raise UnknownFileTypeError,"!Unknown file type: #{descriptor.tape_type.inspect}"
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
          open(fname, :force=>true) do |f|
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
        # debug "Caller: #{caller[0,2].inspect}"
        # debug hash.inspect
        hash
      end
      
      def to_yaml(options={})
        to_hash(options).to_yaml
      end
      
      def write(to=nil)
        to ||= tape_path
        shell = Shell.new
        output = to_yaml
        shell.write to, output
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

      def qualified_path_name(to, shard=nil)
        to ? (shard ? File.join(to, shard) : to) : shard      end

      # TODO Could this be refactored to Frozen and other subclasses?
      def to_decoded_parts(to, options)
        expand = options.delete(:expand)
        if tape_type!=:frozen || options[:shard]
          # Return a file
          {to=>to_decoded_yaml(options)}
        elsif expand
          # Return multiple shards
          parts = {}
          shard_count.times do |shard_number|
            res = to_decoded_hash(options.merge(shard: shard_number))
            path = qualified_path_name(to, res[:shard_name])
            raise CantExpandError, "Must specify file name with :expand" if res[:shard_name] && to=='-'
            parts[path] = res.to_yaml
          end
          parts
        else
          raise CantExpandError, "Must specify either :shard or :expand"
        end
      end

      def decode(to, options={})
        parts = to_decoded_parts(to, options)
        shell = Shell.new
        parts.each do |part, content|
          shell.mkdir_p(File.dirname(part)) unless part.nil? || part=='-'
          shell.write(part, content) unless part.nil?
        end
        parts
      end

      def method_missing(meth, *args, &blk)
        data.send(meth, *args, &blk)
      rescue NoMethodError => e
        raise NoMethodError, %{"#{self.class}##{meth} method not defined:\n  Raised #{e} at:\n#{e.backtrace.map{|c| '    ' + c}.join("\n")}}
      end
    end
  end
end
