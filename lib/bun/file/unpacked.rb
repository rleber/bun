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

        # def create(options={}, &blk)
        #   preamble = nil
        #   if options[:type]
        #     ftype = options[:type]
        #   else
        #     preamble = get_preamble(options)
        #     ftype = preamble.tape_type
        #   end
        #   klass = const_get(ftype.to_s.sub(/^./){|m| m.upcase}) unless ftype.is_a?(Class)
        #   if options[:header]
        #     if ftype == :frozen
        #       limit = Frozen.send(:new, :words=>preamble.words, :header=>true).header_size
        #     else
        #       limit = preamble.header_size
        #     end
        #   else
        #     limit = nil
        #   end
        #   f = klass.send(:new, options.merge(:n=>limit))
        #   res = if block_given?
        #     begin
        #       yield(f)
        #     rescue => e
        #       raise %Q{!Raised error in yield: #{e}\n  Raised #{e} at:\n#{e.backtrace.map{|c| '    ' + c}.join("\n")}}
        #     ensure
        #       f.close
        #     end
        #   else
        #     f
        #   end
        # end
        
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

        def open(fname, options={}, &blk)
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
        
      end

      # CHARACTERS_PER_WORD = characters_per_word
      # PACKED_CHARACTERS_PER_WORD = packed_characters_per_word
      # ARCHIVE_NAME_POSITION = 7 # words
      # SPECIFICATION_POSITION = 11 # words
      # DESCRIPTION_PATTERN = /\s+(.*)/

      # attr_reader :all_characters
      # attr_reader :all_packed_characters
      # attr_reader :characters
      # attr_reader :file_content
      # attr_reader :packed_characters
      # attr_reader :words
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

      # def read
      #   @data.data
      # end
      # 
      # def words=(words)
      #   if words.nil?
      #     @words = @all_characters = @characters = @packed_characters = @descriptor = nil
      #   else
      #     @words = words
      #     @descriptor = Descriptor::Unpacked.new(self)
      #     @all_characters = LazyArray.new(words.size*characters_per_word) do |n|
      #       @words.characters.at(n)
      #     end
      #     @all_packed_characters = LazyArray.new(words.size*packed_characters_per_word) do |n|
      #       @words.packed_characters.at(n)
      #     end
      #     unless header?
      #       @file_content = LazyArray.new(size-content_offset) do |n|
      #         # TODO is this check vs. size necessary? is it correct?
      #         n < self.size ? word(content_offset+n) : nil
      #       end
      #       @characters = LazyArray.new(@file_content.size*characters_per_word) do |n|
      #         @words.characters.at(n + content_offset*characters_per_word)
      #       end
      #       @packed_characters = LazyArray.new(@file_content.size*packed_characters_per_word) do |n|
      #         @words.characters.at(n + content_offset*packed_characters_per_word)
      #       end
      #     end
      #   end
      #   words
      # end
      # 
      # def word(n)
      #   @words.at(n)
      # end
      # 
      # def clear
      #   self.words = nil
      # end
      # 
      # def content
      #   @file_content
      # end
      # 
      # def delimited_string(offset, options={})
      #   delimiter = options[:delimiter] || "\0"
      #   start = offset
      #   if options[:all]
      #     chars = all_characters
      #     chars_per_word = CHARACTERS_PER_WORD
      #   elsif options[:packed]
      #     chars = packed_characters
      #     chars_per_word = PACKED_CHARACTERS_PER_WORD
      #   else
      #     chars = characters
      #     chars_per_word = CHARACTERS_PER_WORD
      #   end
      #   size = chars.size
      #   offset *= chars_per_word if options[:word_offset]
      #   string = ""
      #   loop do
      #     break if offset >= size
      #     word_index, ch_index = offset.divmod(chars_per_word)
      #     word = word(word_index)
      #     break if !word || (word == self.class.eof_marker && !options[:all])
      #     char = chars.at(offset)
      #     break if char == delimiter
      #     string << char
      #     offset += 1
      #   end
      #   string
      # end
      # 
      # def content_offset
      #   self.class.content_offset(words)
      # end
      # 
      # def header_size
      #   content_offset
      # end
      # 
      # def size(options={})
      #   # TODO Should :eof be the default? (Is there ever a meaningful eof marker in frozen files?)
      #   if options[:eof]
      #     eof_tape = nil
      #     words.each_with_index do |word, index|
      #       if word.value == self.class.eof_marker
      #         eof_tape = index
      #         break
      #       end
      #     end
      #     eof_tape || size
      #   elsif options[:all]
      #     @words.size
      #   else
      #     @size || tape_size
      #   end
      # end
      # 
      # def tape_size
      #   res = (word(0).half_word(1))+1
      #   res = res.value unless res.is_a?(Fixnum)
      #   res
      # end
      # 
      # def date(tape)
      #   date_string = content[tape,2].characters.join
      #   self.class.date(date_string)
      # end
      # 
      # def time_of_day(tape)
      #   self.class.time_of_day content.at(tape)
      # end
      # 
      # def time(date_tape, time_tape)
      #   self.class.time date(date_tape), time_of_day(time_tape)
      # end
      # 
      # def catalog_time
      #   archive && archive.catalog_time(tape)
      # end
      # 
      # def characters_per_word
      #   self.class.characters_per_word
      # end
      # 
      # def packed_characters_per_word
      #   self.class.packed_characters_per_word
      # end
      # 
      # def frozen?
      #   File::Frozen::Descriptor.frozen?(self)
      # end
      
      def tape_type
        descriptor.tape_type
      end
      
      def file_time
        descriptor.file_time
      end
      
      def to_yaml
        hash = descriptor.to_hash.merge(:content=>data.data)
        if tape_type == :frozen
          hash[:shards] = shard_descriptors.map do |d|
            {
              :name      => d.name,
              :file_time => d.file_time,
              :blocks    => d.blocks,
              :start     => d.start,
              :size      => d[:size], # Need to do it this way, because d.size is the builtin
            }
          end
        end
        hash.to_yaml
      end
      
      def write(to=nil)
        to ||= tape_path
        shell = Shell.new
        shell.write to, to_yaml
      end
      
      def unpack
        self
      end
      
      def to_hash(options={})
        descriptor.to_hash.merge(
          content:     decoded_text(options),
          data_format: :unpacked,
          decode_time: Time.now,
          decoded_by:  Bun.expanded_version
        )
      end

      # Subclasses must define decoded_text
      def decode(to, options={})
        Shell.new.write(to,to_hash(options).to_yaml)
      end

      def method_missing(meth, *args, &blk)
        data.send(meth, *args, &blk)
      rescue NoMethodError => e
        raise NoMethodError, %{"#{self.class}##{meth} method not defined:\n  Raised #{e} at:\n#{e.backtrace.map{|c| '    ' + c}.join("\n")}}
      end
    end
  end
end
