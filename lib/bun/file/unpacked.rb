#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'date'

module Bun

  class File < ::File
    class UnknownFileTypeError < RuntimeError; end
    class UnexpectedTapeTypeError < RuntimeError; end
    class InvalidInputError < RuntimeError; end
    class CantExpandError < RuntimeError; end
    class CantDecodeError < RuntimeError; end
    class SkippingFileError < RuntimeError; end
    
    class Unpacked < Bun::File
      class << self
        
        def read_information(fname)
          Bun.cache(:unpacked_yaml, File.expand_path(fname)) do
            input = begin
              YAML.load(Bun::File.read(fname))
            rescue => e
              raise InvalidInputError, "Error reading #{fname}: #{e}"
            end
            raise InvalidInputError "Expected #{fname} to be a Hash, not a #{input.class}" \
              unless input.is_a?(Hash)
            input
          end
        end
        
        def build_data(input, options={})
          @data = input.delete(:content)
          @content =
            Data.new(
              :data=>@data, 
              :archive=>options[:archive], 
              :tape=>options[:tape], 
            )
        end
        
        def build_descriptor(input)
          @descriptor = Descriptor::File.from_hash(@content,input)
        end

        # TODO How is this different from File.descriptor?
        def build_descriptor_from_file(fname)
          if File.packed?(fname) 
            File::Packed.open(fname) {|f| f.descriptor }
          elsif File.binary?(fname) # Baked
            nil
          else
            input = read_information(fname)
            build_descriptor(input)
          end
        end

        attr_accessor :content, :data, :descriptor

        # TODO Woof! This is getting really smelly
        def forced_open(fname, options={}, &blk)
          input = read_information(fname)
          input.merge!(tape_path: fname)
          klass = options[:as_class] || self # So that File::Decoded can force open as File::Unpacked
          klass.build_data(input, options)
          klass.build_descriptor(input)
          options = options.merge(:data=>klass.data, :descriptor=>klass.descriptor, :tape_path=>options[:fname])
          if options[:type] && klass.descriptor[:type]!=options[:type]
            msg = "Expected file #{fname} to be a #{options[:type]} file, not a #{klass.descriptor[:type]} file"
            # TODO Remove this option; use exception handling, instead
            if options[:graceful]
              stop "!#{msg}"
            else
              raise UnexpectedTapeTypeError, msg
            end
          end
          file = klass.create(options)
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
          elsif (fmt = File.format(fname)) != :unpacked
            if options[:promote]
              if File.format_level(fmt) < File.format_level(:unpacked)
                t = Tempfile.new('promoted_to_unpacked_')
                t.close
                # TODO redo this:
                # super(fname, options) {|f| f.unpack(t.path, options)}
                File.unpack(fname, t.path, force: true, fix: options[:fix]) # Need --force, tempfile exists
                # puts "Unpacked file:" # debug
                # system("cat #{t.path} | more")
                File::Unpacked.open(t.path, options, &blk)
              else
                raise BadFileFormat, "#{fname} is a #{fmt} format file, and can't be converted to unpacked"
              end
            else
              raise BadFileFormat, "#{fname} is a #{fmt} format file, not an unpacked file"
            end
          else
            forced_open(fname, options, &blk)
          end
        end
        
        def create(options={})
          descriptor = options[:descriptor]
          type = options[:force_type] || descriptor[:type]
          case type
          when :text
            File::Unpacked::Text.new(options)
          when :frozen
            File::Unpacked::Frozen.new(options)
          when :huffman
            File::Unpacked::Huffman.new(options)
          when :executable
            File::Unpacked::Executable.new(options)
          else
            if options[:strict]
              raise UnknownFileTypeError,"!Unknown file type: #{descriptor.type.inspect}"
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

        def decode(fname, to, options={}, &blk)
          open(fname, options) do |f|
            f.decode(to, options, &blk)
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
      
      def type
        descriptor.type
      end
      
      def time
        descriptor.time
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
        format = options.delete(:format)
        fields[:format] = format || :unpacked
        fields[:digest]  = content.digest
        if type == :frozen
          shards = shard_descriptors.map do |d|
            {
              :name      => d.name,
              :time => d.time,
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
        hash.delete(:promote)
        hash.delete(:tape_path)
        hash.delete(:fields)
        # debug "Caller: #{caller[0,2].inspect}"
        # debug hash.inspect
        hash
      end
      
      def to_yaml(options={})
        to_hash(options).to_yaml
      end
      
      def write(to=nil, options={})
        to ||= descriptor.tape_path
        shell = Shell.new
        output = to_yaml(options)
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
        llinks = self.llink_count rescue nil # Frozen and huffman files don't have llinks
        text = decoded_text(options)
        return nil unless text
        text = text.scrub if options[:scrub]
        options = options.merge(
                    content:       text, 
                    format:        :decoded,
                    decode_time:   Time.now,
                    decoded_by:    Bun.expanded_version,
                    text_size:     text.size,
                    media_codes:   media_codes,
                    multi_segment: multi_segment,
                  )
        options[:llink_count] = llinks if llinks
        to_hash(options)
      end
      
      def to_decoded_yaml(options={})
        hash = to_decoded_hash(options)
        raise "contains :fields: #{hash.inspect}" if hash.keys.map{|k| k.to_s}.include?('fields')
        hash.to_yaml
      end

      def qualified_path_name(to, shard=nil)
        to ? (shard ? File.join(to, shard) : to) : shard      
      end

      def to_decoded_parts(to, options)
      # TODO Could this be refactored to Frozen and other subclasses?
        expand = options.delete(:expand)
        allow = options.delete(:allow)
        if type!=:frozen || options[:shard]
          # Return a file
          [{path: to, content: to_decoded_yaml(options), from: descriptor.tape_path, shard: nil}]
        elsif expand
          # Return multiple shards
          parts = []
          shard_count.times do |shard_number|
            res = to_decoded_hash(options.merge(shard: shard_number))
            break unless res
            path = qualified_path_name(to, res[:shard_name])
            raise CantExpandError, "Must specify file name with :expand" if res[:shard_name] && to=='-'
            parts << {path: path, content: res.to_yaml, from: descriptor.tape_path, shard: res[:shard_name]}
          end
          parts
        else
          raise CantExpandError, "Must specify either :shard or :expand"
        end
      end

      def decode(to, options={}, &blk)
        # Need to delete these, otherwise they'll end up in the file descriptor
        force = options.delete(:force)
        quiet = options.delete(:quiet)
        continue = options.delete(:continue)
        to_path = options.delete(:to_path)
        _raise = options.delete(:raise)
        parts = to_decoded_parts(to, options)
        unless parts
          yield(self, 0) if block_given? # In case some reporting needs to be done
          return nil
        end
        shell = Shell.new
        parts.each.with_index do |part_hash, index|
          part = part_hash[:path]
          content = part_hash[:content]
          part = yield(self, index) if block_given? # Block overrides "to"
          if !part.nil? && (block_given? || !to.nil?)
            if !force && (conflicting_part = File.conflicts?(part))
              if quiet
                stop unless continue
              else
                message_part = File.basename(part_hash[:from])
                message_part = message_part + "[#{part_hash[:shard]}]" if part_hash[:shard]
                if to
                  conflicting_part = 'it' if conflicting_part == to
                else
                  conflicting_part = File.relative_path(conflicting_part, relative_to: to_path)
                end
                msg = "Skipped #{message_part}: #{conflicting_part} already exists"
                if _raise
                  raise SkippingFileError, msg
                elsif continue
                  message_path = part_hash[:shard] ? "#{::File.expand_path(part_hash[:from])}[#{part_hash[:shard]}]" : part_hash[:from]
                  File.replace_messages message_path, msg
                else
                  stop msg
                end
              end
            else
              shell.mkdir_p(File.dirname(part)) unless part=='-'
              shell.write(part, content)
            end
          end
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
