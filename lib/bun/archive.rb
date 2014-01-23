#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

require 'lib/bun/collection'
require 'lib/bun/catalog'
require 'lib/bun/file'
require 'date'
require 'shellwords'
require 'tempfile'

module Bun
  class Archive < Collection
    class InvalidStep < ArgumentError; end
    class MissingCatalog < ArgumentError; end
    class DirectoryConflict < ArgumentError; end
    class TarError < RuntimeError; end

    
    class << self
      def enumerator_class
        Archive::Enumerator
      end
      
      TRANSLATE_STEPS = %w{pull unpack catalog decode compress bake tests}
      def translate_steps
        TRANSLATE_STEPS
      end

      # Steps:
      # pull                      Pull files from the original archive
      # unpack                    Unpack the files (from Honeywell binary format)
      # catalog                   Catalog the files (using a catalog file)
      # decode                    Decode the files
      # compress                  Compress the baked library (e.g. remove duplicates)
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
      def translate(from, to, options={})
        stages = %w{packed unpacked cataloged decoded compressed baked compressed_baked}
        @directories = {}
        @symlinks = {}
        stages.each do |stage|
          @directories[stage.to_sym] = File.expand_path(File.join(to, stage))
          @symlinks[stage.to_sym] = options[:links] + '_' + stage if options[:links]
        end
        do_translate_steps(options).each do |step|
          case step
          when 'pull'
            # TODO DRY this up
            warn "Pull files from the original archive" unless options[:quiet]
            clear_stage :packed
            pull from, @directories[:packed]
            build_symlink :packed if options[:links]
          when 'unpack'
            warn "Unpack the files (from Honeywell binary format)" unless options[:quiet]
            clear_stage :unpacked
            clear_stage :cataloged
            unpack @directories[:packed], @directories[:unpacked]
            build_symlink :unpacked if options[:links]
          when 'catalog'
            warn "Catalog the files (using a catalog file)" unless options[:quiet]
            raise MissingCatalog, "No catalog specified" unless options[:catalog]
            clear_stage :cataloged
            catalog @directories[:unpacked], @directories[:cataloged], :catalog=>options[:catalog]
            build_symlink :cataloged if options[:links]
          when 'decode'
            warn "Decode the files" unless options[:quiet]
            from = if File.exists?(@directories[:cataloged])
              @directories[:cataloged]
            else
              @directories[:unpacked]
            end
            clear_stage :decoded
            decode from, @directories[:decoded]
            build_symlink :decoded if options[:links]
          when 'compress'
            warn "Compress the files" unless options[:quiet]
            from = @directories[:decoded]
            clear_stage :compressed
            compress @directories[:decoded], @directories[:compressed]
            build_symlink :decoded if options[:links]
          when 'bake'
            warn "Bake the files (i.e. remove metadata)" unless options[:quiet]
            clear_stage :baked
            bake @directories[:compressed], @directories[:baked]
            build_symlink :baked if options[:links]
          when 'tests'
            warn "Rebuild test cases" unless options[:quiet]
            system('bun test build')
          else
            raise InvalidStep, "Unknown step #{step}"
          end
        end
      end

      def do_translate_steps(options={})
        test = options[:tests]
        all_steps = TRANSLATE_STEPS + %w{all}

        # Convert all steps to lowercase, unabbreviated
        steps = options[:steps] || 'all'
        steps = steps.split(',') do |orig_step|
          step = orig_step.strip.downcase
          if step =~ /^((?:\.\.\.?|not[-_]?)?)(\w)((?:\.\.\.?)?)$/
            ix = all_steps.index($2)
            raise InvalidStep, "Unknown step #{orig_step.inspect}" unless ix
            step = $1 + all_steps[ix] + $3
          end
          step
        end
        
        if steps.size==0 || (steps.size==1 && steps.first =~ /^not/)
          args.unshift 'all'
        end
        
        # Expand shorthands and check argument validity
        steps = steps.inject([]) do |ary, step|
          case step
          when '..all', 'all..', /^not[-_]?all/
            raise InvalidStep, "Step #{step} is not allowed"
          when 'all'
            ary += TRANSLATE_STEPS
          when /^not[-_]?(\w+)$/
            ary -= [$1]
          when /^(\w*)(\.\.\.?)(\w*)$/
            ix1 = $1=='' ? 0 : TRANSLATE_STEPS.index($1)
            raise InvalidStep, "Unknown step #{$1}" unless ix1
            ix2 = $3=='' ? -1 : TRANSLATE_STEPS.index($3)
            raise InvalidStep, "Unknown step #{$2}" unless ix2
            if $2 == '..' || ix2 == -1
              ary += TRANSLATE_STEPS[ix1..ix2]
            else
              ary += TRANSLATE_STEPS[ix1...ix2]
            end
          else
            raise InvalidStep, "Unknown step #{step}" unless TRANSLATE_STEPS.index(step)
            ary << step
          end
          ary
        end

        steps << 'tests' if options[:tests] # Test isn't automatically part of the sequence
                                            # This syntax allows translate --tests all
        steps = steps.uniq
        index = 0
        step_numbers = TRANSLATE_STEPS.inject({}) do |hsh, step|
          hsh[step] = index
          index += 1
          hsh
        end
        if steps.include?('unpack') && !steps.include?('catalog')
          warn "Steps include unpack, but not catalog -- be careful! Cataloged directory will be erased"
        end
        steps.sort_by{|step| step_numbers[step] }
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
        Archive.new(from).unpack(to, options)
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

      def compress(from, to=nil, options={})
        shell = Shell.new
        if options[:dryrun]
          dest = to
        elsif to
          shell.rm_rf(to)
          shell.cp_r(from, to)
          dest = to
        else
          dest = from
        end

        Archive.new(dest).compress(options)
      end

      def tar(archive, tar_file, options={})
        Archive.new(archive).tar(tar_file, options)
      end

      def build_symlink(stage)
        `ln -s #{@directories[stage]} #{@symlinks[stage]}`
      end
      
      def glob_all(files)
        files.map do |f|
          path = File.expand_path(f)
          if File.directory?(f)
            Dir.glob(File.join(f,'**','*'))
          else
            f
          end
        end.flatten
      end
      
      def examine_select(files, options={}, &blk)
        begin
          test_value = eval(options[:value]) if options[:value]
        rescue => e
          raise Formula::EvaluationError, "Error evaluating value: #{e}"
        end
        glob_all(files).map do |file|
          res=false
          begin
            if !File.directory?(file)
              result = Bun::File.examination(file, options)
              code = result[:code] || 0
              if options[:value]
                code = test_value == result[:result] ? 0 : 1
              elsif options[:formula]
                code = result[:result] ? 0 : 1
              end
              res = code==0
              if res
                result = result.merge(file: file)
                yield(result) if block_given?
              end
            end
          rescue Formula::EvaluationError => e
            warn "!Evaluation error: #{e}" unless options[:quiet]
            res = nil
          rescue String::Examination::Invalid => e
            warn "!Invalid analysis: #{options[:exam]}" unless options[:quiet]
            res = nil
          end
          res
        end
      end
        
      def examine_map(expr, files, options={}, &blk)
        glob_all(files).map do |file|
          begin
            if !File.directory?(file)
              exam = Bun::File.examination(file, expr, options)
              code = exam.code || 0
              res = exam.value(raise: options[:raise])
              res = res ? 'match' : 'no_match' if options[:match]
              if options[:value]
                code = options[:value] == res ? 0 : 1
              end
              result = {file: file, code: exam.code, result: res}
              result = yield(result) if block_given?
              result
            end
          rescue Expression::EvaluationError => e
            warn "!Evaluation error: #{e}" unless options[:quiet]
            {file: file, result: nil, code: 0}
          rescue String::Examination::Invalid => e
            warn "!Invalid analysis: #{options[:exam]}" unless options[:quiet]
            {file: file, result: nil, code: 0}
          end
        end
      end

      def duplicates(exam, files, options={})
        table = []
        examine_map(exam, files, options) do |result| 
          res = result[:result]
          res = res.value if res.class.to_s =~ /Wrapper/ # A bit smelly
          res = res.value if res.class.to_s =~ /Wrapper/ # A bit smelly
          last_result = res
          row = [result[:file], res].flatten
          table << row
        end
        
        # Find duplicates
        counts_hash = {}
        table.each do |row|
          key = row[1..-1]
          counts_hash[key] ||= 0
          counts_hash[key] += 1
        end

        table = table.sort_by{|row| row.rotate }

        duplicates = {}
        table.each do |row|
          key = row[1..-1]
          if (counts_hash[key]||0) > 1
            duplicates[key] ||= []
            duplicates[key] << row[0]
          end
        end
        sorted_duplicates = {}
        fail = false
        duplicates.each do |key, files|
          sorted_duplicates[key] = files.sort_by {|file| File.timestamp(file) }
        end
        sorted_duplicates
      end

    end
    
    # TODO Is there a more descriptive name for this?
    def contents(&blk)
      tapes = self.tapes
      contents = []
      each do |tape|
        file = open(tape)
        if file.type == :frozen
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
        
    def unpack(to, options={})
      to_path = expand_path(to, :from_wd=>true) # @/foo form is allowed
      FileUtils.rm_rf to_path unless options[:dryrun]
      leaves.each do |tape|
        from_tape = relative_path(tape, from_wd: true)
        to_file = from_tape
        if to_file =~ /^(.*)(\.[a-zA-Z]+)$/
          case $2
          when Bun::DEFAULT_DECODED_FILE_EXTENSION, Bun::DEFAULT_BAKED_FILE_EXTENSION
            # Do nothing
          else
            to_file = $1 + Bun::DEFAULT_UNPACKED_FILE_EXTENSION
          end
        else
            to_file += Bun::DEFAULT_UNPACKED_FILE_EXTENSION
        end
        to_file  = File.join(to_path, to_file)
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
      leaves.each do |tape_path|
        decode_options = options.merge(promote: true, expand: true, allow: true)
        File.decode(tape_path, nil, decode_options) do |file, index|
          # Determine whether to decode tape, and if so, where to put it
          tape = relative_path(tape_path)
          to_tape_path = case file.descriptor.format
          when :packed, :unpacked
            case typ=file.type
            when :frozen
              descr = file.shard_descriptor(index)
              shard_name = descr.name
              warn "Decoding #{tape}[#{shard_name}]" if options[:dryrun] || !options[:quiet]
              timestamp = file.descriptor.timestamp
              File.join(to_path, decode_path(file.path, timestamp), shard_name.sub(/\.+$/,''),
                      decode_tapename(tape, descr.file_time))
            when :text, :huffman
              warn "Decoding #{tape}" if options[:dryrun] || !options[:quiet]
              timestamp = file.descriptor.timestamp
              File.join(to_path, file.path.sub(/\.+$/,''), decode_tapename(tape, timestamp))
            else
              warn "Skipping #{tape}: Unknown type (#{typ})" if options[:dryrun] || !options[:quiet]
              nil # Force skip file
            end
          else
            warn "Copying #{tape}" if options[:dryrun] || !options[:quiet]
            File.join(to_path, tape)
          end
          options[:dryrun] ? nil : to_tape_path # Force skipping of file if :dryrun
        end
      end
    end
    
    EXTRACT_DATE_FORMAT = "%Y%m%d_%H%M%S"
    EXTRACT_TAPE_PREFIX = 'tape.'
    EXTRACT_TAPE_SUFFIX = '.txt'

    def decode_path(path, date)
      path = path.sub(/#{DEFAULT_UNPACKED_FILE_EXTENSION}$/,'').sub(/\.+$/,'')
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

    def compress(options={})
      files = leaves.to_a
      shell = Shell.new
      
      # Phase I: Remove duplicates
      duplicates('digest').each do |key, files|
        duplicate_files = files[1..-1]
        duplicate_files.each do |file|
          rel_file = relative_path(file)
          warn "Delete #{rel_file}" unless options[:quiet]
          shell.rm_rf(file) unless options[:dryrun]
        end
      end

      # Phase II: Remove tape files, if there's no difference between them
      compact_groups(options) {|path| File.dirname(path) }
      
      # Phase III: Compress dated freeze file archives
      compact_groups(options) {|path| path.sub(/_\d{8}(?:_\d{6})?(?=\/)/,'') }

      # Phase IV: Remove empty directories
      # Thanks to http://stackoverflow.com/questions/1290670/ruby-how-do-i-recursively-find-and-remove-empty-directories
      all.select { |d| File.directory?(d)} \
         .reverse_each do |d| 
            if ((Dir.entries(d) - %w[ . .. ]).empty?)
              rel_directory = relative_path(d)
              warn "Delete #{rel_directory}" unless options[:quiet]
              Dir.rmdir(d)
            end
          end
    end

    def duplicates(exam, options={})
      Archive.duplicates(exam, leaves.to_a, options)
    end

    def compact_groups(options={}, &blk)
      shell = Shell.new
      groups = leaves.to_a.group_by {|path| yield(path) }
      # puts groups.inspect
      groups.each do |group, files|
        case files.size
        when 0
          # Shouldn't happen
        when 1
          file = files.first
          unless file == group
            rel_file = relative_path(file)
            rel_group = relative_path(group)
            warn "Compact #{rel_file} => #{rel_group}" unless options[:quiet]
            new_file = group
            new_file += File.extname(file) unless File.extname(new_file)==File.extname(file)
            temp_file = group+".tmp"
            shell.mkdir_p(File.dirname(temp_file))
            shell.cp(file, temp_file)
            shell.rm_rf(file)
            shell.rm_rf(group)
            shell.cp(temp_file, new_file)
            shell.rm_rf(temp_file)
          end
        else
          sorted_files = files.map {|file| [file, File.timestamp(file)] }.sort_by {|file, date| date }
          sorted_files.each.with_index do |file_data, index|
            file, date = file_data
            suffix = ".v#{index+1}"
            new_file = group + suffix
            new_file += File.extname(file) unless File.extname(new_file)==File.extname(file)
            shell.mkdir_p(File.dirname(new_file))
            shell.cp(file, new_file)
            shell.rm_rf(file)
            rel_file = relative_path(file)
            rel_new_file = relative_path(new_file)
            warn "Move #{rel_file} => #{rel_new_file}" unless options[:quiet]
          end
          shell.rm_rf(group)
        end
      end
    end

    def tar(tar_file, options={})
      tar_file = File.expand_path(tar_file)
      tar_file += '.tar.bz2' unless File.extname(tar_file) != ''
      Shell.new.rm_rf(tar_file)
      Dir.chdir(at) do
        cmd = "tar cvjf #{tar_file.inspect} ."
        t = Tempfile.new("tar")
        t.close
        output = %x{#{cmd} 2>&1}
        unless $? == 0
          $stderr.puts output
          raise TarError, "#{cmd} failed with exit code #{$?}"
        end
        system("tar tvf #{tar_file.inspect}") unless options[:quiet]
      end
    end
  end
end