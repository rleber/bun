#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

require 'lib/bun/collection'
require 'lib/bun/catalog'
require 'lib/bun/file'
require 'date'
require 'shellwords'

module Bun
  class Archive < Collection
    class InvalidStep < ArgumentError; end
    class MissingCatalog < ArgumentError; end
    class DirectoryConflict < ArgumentError; end
    
    class << self
      def enumerator_class
        Archive::Enumerator
      end
      
      FETCH_STEPS = %w{pull unpack catalog decode classify bake tests}
      def fetch_steps
        FETCH_STEPS
      end

      # Steps:
      # pull                      Pull files from the original archive
      # unpack                    Unpack the files (from Honeywell binary format)
      # catalog                   Catalog the files (using a catalog file)
      # decode                    Decode the files
      # classify                  Classify the decoded files into clean and dirty
      # bake                      Bake the files (i.e. remove metadata)
      # tests                     Rebuild the test cases for the bun software
      # all                       Run all the steps
      #
      # Some convenience abbreviations are allowed:
      #   not-xxx (or not_xxx or notxxx)  Exclude this step
      #   all  (or .. or ...)             Include all steps
      #   ..xxx                           All steps leading up to xxx
      #   ...xxx                          All steps up to (but not including) xxx
      #   xxx.. (or xxx...)               All steps beginning with xxx
      #   xxx..yyy                        Steps xxx to yyy
      #   xxx...yyy                       Steps xxx to the step before yyy
      #
      # Last argument may be an options hash; allowed options: 
      #   :announce  Boolean: announce each step?
      #   :catalog   Catalog file
      #   :source    Original source directory
      #   :links     Prefix pattern for symlink names
      #   :tests     Boolean: rebuild test cases?
      #   :to        Directory to output archives to
      def fetch(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        stages = %w{packed unpacked cataloged decoded classified baked}
        base_directory = options[:to]
        @directories = {}
        @symlinks = {}
        stages.each do |stage|
          @directories[stage.to_sym] = File.expand_path(File.join(base_directory, stage))
          @symlinks[stage.to_sym] = options[:links] + '_' + stage
        end
        process_steps(*args, options).each do |step|
          case step
          when 'pull'
            warn "Pull files from the original archive" if options[:announce]
            clear_stage :packed
            pull options[:source], @directories[:packed]
            build_symlink :packed
          when 'unpack'
            warn "Unpack the files (from Honeywell binary format)" if options[:announce]
            clear_stage :unpacked
            clear_stage :cataloged
            unpack @directories[:packed], @directories[:unpacked]
            build_symlink :unpacked
          when 'catalog'
            warn "Catalog the files (using a catalog file)" if options[:announce]
            raise MissingCatalog, "No catalog specified" unless options[:catalog]
            clear_stage :cataloged
            catalog @directories[:unpacked], @directories[:cataloged], :catalog=>options[:catalog]
            build_symlink :cataloged
          when 'decode'
            warn "Decode the files" if options[:announce]
            from = if File.exists?(@directories[:cataloged])
              @directories[:cataloged]
            else
              @directories[:unpacked]
            end
            clear_stage :decoded
            decode from, @directories[:decoded], :catalog=>options[:catalog]
            build_symlink :decoded
          when 'classify'
            warn "Classify the decoded files into clean and dirty" if options[:announce]
            clear_stage :classified
            classify @directories[:decoded], @directories[:classified]
            build_symlink :classified
          when 'bake'
            warn "Bake the files (i.e. remove metadata)" if options[:announce]
            clear_stage :baked
            bake @directories[:classified], @directories[:baked]
            build_symlink :baked
          when 'tests'
            warn "Rebuild test cases" if options[:announce]
            system('bun test build')
          else
            raise InvalidStep, "Unknown process step #{step}"
          end
        end
      end

      def process_steps(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        test = options[:tests]
        all_steps = FETCH_STEPS + %w{all}

        # Convert all steps to lowercase, unabbreviated
        args = args.map do |orig_arg|
          arg = orig_arg.to_s.strip.downcase
          if arg =~ /^((?:\.\.\.?|not[-_]?)?)(\w)((?:\.\.\.?)?)$/
            ix = all_steps.index($2)
            raise InvalidStep, "Unknown process step #{orig_arg.inspect}" unless ix
            arg = $1 + all_steps[ix] + $3
          end
          arg
        end
        
        if args.size==0 || (args.size==1 && args.first =~ /^not/)
          args.unshift 'all'
        end
        
        # Expand shorthands and check argument validity
        steps = args.inject([]) do |ary, arg|
          case arg
          when '..all', 'all..', /^not[-_]?all/
            raise InvalidStep, "Step #{arg} is not allowed"
          when 'all'
            ary += FETCH_STEPS
          when /^not[-_]?(\w+)$/
            ary -= [$1]
          when /^(\w*)(\.\.\.?)(\w*)$/
            ix1 = $1=='' ? 0 : FETCH_STEPS.index($1)
            raise InvalidStep, "Unknown process step #{$1}" unless ix1
            ix2 = $3=='' ? -1 : FETCH_STEPS.index($3)
            raise InvalidStep, "Unknown process step #{$2}" unless ix2
            if $2 == '..' || ix2 == -1
              ary += FETCH_STEPS[ix1..ix2]
            else
              ary += FETCH_STEPS[ix1...ix2]
            end
          else
            raise InvalidStep, "Unknown process step #{arg}" unless FETCH_STEPS.index(arg)
            ary << arg
          end
          ary
        end

        steps << 'tests' if options[:tests] # Test isn't automatically part of the sequence
                                          # This syntax allows process --tests all
        steps = steps.uniq
        index = 0
        step_numbers = FETCH_STEPS.inject({}) do |hsh, step|
          hsh[step] = index
          index += 1
          hsh
        end
        if steps.include?('unpack') && !steps.include?('catalog')
          warn "Steps include unpack, but not catalog -- be careful! Cataloged directory will be erased"
        end
        steps.sort_by{|arg| step_numbers[arg] }
      end
      
      def clear_stage(stage)
        `rm -f #{@symlinks[stage]}`
        `rm -rf #{@directories[stage]}`
      end
      
      # Must be done this way, in case there is a symlink to the to directory
      def copy(from, to, options={})
        expanded_to = File.expand_path(to)
        unless options[:force]
          raise DirectoryConflict, "Directory #{expanded_to} already exists" \
                  if File.exists?(expanded_to)
        end
        system(['rm', '-rf', expanded_to].shelljoin)
        system(['cp', '-r', File.expand_path(from) + "/", expanded_to + "/"].shelljoin)
      end
      
      def pull(from, to, options={})
        copy from, to, :force=>true
      end
      
      def unpack(from, to, options={})
        Archive.new(from).unpack('**/*', to, options)
      end
      
      def catalog(from, to=nil, options={})
        raise MissingCatalog, "options[:catalog] not supplied" unless options[:catalog]
        if to
          copy from, to, :force=>true
        else
          to = from
        end
        archive = Archive.new(to)
        archive.apply_catalog(options[:catalog], options)
      end
      
      def decode(from, to, options={})
        Archive.new(from).decode(to, options)
      end
      
      def classify(from, to, options={})
        Library.new(from).classify(to, options)
      end
      
      def bake(from, to, options={})
        Library.new(from).bake(to, options)
      end

      def build_symlink(stage)
        `ln -s #{@directories[stage]} #{@symlinks[stage]}`
      end
    end
    
    # TODO Is there a more descriptive name for this?
    def contents(&blk)
      tapes = self.tapes
      contents = []
      each do |tape|
        file = open(tape)
        if file.tape_type == :frozen
          file.shard_count.times do |i|
            contents << "#{tape}[#{file.shard_name(i)}]"
          end
        else
          contents << tape
        end
      end
      if block_given?
        contents.each(&blk)
      end
      contents
    end
        
    def unpack(glob, to, options={})
      to_path = expand_path(to, :from_wd=>true) # @/foo form is allowed
      FileUtils.rm_rf to_path unless options[:dryrun]
      Dir.glob(expand_path(glob)).each do |tape|
        from_tape = relative_path(tape, :relative_to=>File.expand_path(at))
        from_tape.sub!(/#{Bun::DEFAULT_PACKED_FILE_EXTENSION}$/,'')
        to_file  = File.join(to_path, from_tape + Bun::DEFAULT_UNPACKED_FILE_EXTENSION)        
        warn "unpack #{from_tape} => #{to_file}" if options[:dryrun] || !options[:quiet]
        unless options[:dryrun]
          dir = File.dirname(to_file)
          FileUtils.mkdir_p dir
          File.unpack(expand_path(from_tape), to_file) unless options[:dryrun]
        end
      end
      to_archive = self.class.new(to_path)
      to_archive.set_timestamps(:quiet=>true)
    end

    # TODO Add glob capability?
    def decode(to, options={})
      to_path = expand_path(to, :from_wd=>true) # @/foo form is allowed
      FileUtils.rm_rf to_path unless options[:dryrun]
      tapes.each do |tape|
        file = open(tape)
        case file.tape_type
        when :frozen
          file.shard_count.times do |i|
            descr = file.shard_descriptor(i)
            shard_name = descr.name
            warn "decode #{tape}[#{shard_name}]" if options[:dryrun] || !options[:quiet]
            unless options[:dryrun]
              timestamp = file.descriptor.timestamp
              f = File.join(to_path, decode_path(file.path, timestamp), shard_name,
                    decode_tapename(tape, descr.file_time))
              dir = File.dirname(f)
              FileUtils.mkdir_p dir
              file.decode f, :shard=>shard_name
            end
          end
        when :text
          warn "decode #{tape}" if options[:dryrun] || !options[:quiet]
          unless options[:dryrun]
            timestamp = file.descriptor.timestamp
            f = File.join(to_path, file.path, decode_tapename(tape, timestamp))
            dir = File.dirname(f)
            FileUtils.mkdir_p dir
            file.decode f
          end
        else
          warn "skipping #{tape}: unknown type (#{file.tape_type})" \
                if options[:dryrun] || !options[:quiet]
        end
      end
    end
    
    EXTRACT_DATE_FORMAT = "%Y%m%d_%H%M%S"
    EXTRACT_TAPE_PREFIX = 'tape.'
    EXTRACT_TAPE_SUFFIX = '.txt'

    def decode_path(path, date)
      path = path.sub(/#{DEFAULT_UNPACKED_FILE_EXTENSION}$/,'')
      if date
        date_to_s = date.strftime(EXTRACT_DATE_FORMAT)
        date_to_s = $1 if date_to_s =~ /^(.*)_000000$/
        path + '_' + date_to_s
      else
        path
      end
    end

    def decode_tapename(path, date)
      EXTRACT_TAPE_PREFIX + decode_path(path, date) + EXTRACT_TAPE_SUFFIX
    end
    
    def items(&blk)
      to_enum.items(&blk)
    end
    
    def fragments(&blk)
      to_enum.fragments(&blk)
    end
    
    def folders(&blk)
      to_enum.folders(&blk)
    end
  end
end