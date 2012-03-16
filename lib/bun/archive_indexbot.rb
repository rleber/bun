class Bun
  class Archive
    class IndexBot < Thor
    
      desc "build", "Build file index for archive"
      option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
      option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
      def build
        # TODO the following two lines are a common pattern; refactor
        directory = options[:archive] || Archive.location
        archive = Archive.new(directory)
        archive.build_and_save_index(:verbose=>!options[:quiet])
      end
    
      desc "clear", "Clear file index for archive"
      option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
      def clear
        # TODO the following two lines are a common pattern; refactor
        directory = options[:archive] || Archive.location
        archive = Archive.new(directory)
        archive.clear_index
      end

      desc "ls_original", "List the original index file for the archive"
      option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
      def ls_original
        archive = Archive.new(options[:archive])
        # TODO Use Array.justify_rows
        archive.original_index.each do |spec|
          puts "#{spec[:tape]}  #{spec[:date].strftime('%Y/%d/%m')}  #{spec[:file]}"
        end
      end
      
      desc "set_dates", "Set file modification dates for archived files, based on original index"
      option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
      option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually set dates"
      def set_dates
        archive = Archive.new(options[:archive])
        shell = Bun::Shell.new(options)
        archive.each do |tape|
          descr = archive.descriptor(tape)
          timestamp = descr[:updated]
          if timestamp
            puts "About to set timestamp: #{tape} #{timestamp.strftime('%Y/%m/%d %H:%M:%S')}" unless options[:quiet]
            shell.set_timestamp(archive.expanded_tape_path(tape), timestamp)
          else
            puts "No updated time available for #{tape}" unless options[:quiet]
          end
        end
      end
      
      VALID_MESSAGES = %w{missing name old new old_file new_file}
      DATE_FORMAT = '%Y/%m/%d %H:%M:%S'
      # TODO Create check method: Check that an index file entry exists for each tape
      # file, check frozen file dates and content vs. index, check 
      # text archive file contents vs. index
      desc "check_original", "Check contents of the original index"
      option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
      option "build",   :aliases=>"-b", :type=>'boolean', :desc=>"Don't rely on archive index; always build information from source file"
      option "include", :aliases=>'-i', :type=>'string',  :desc=>"Include only certain messages. Options include #{VALID_MESSAGES.join(',')}"
      option "exclude", :aliases=>'-x', :type=>'string',  :desc=>"Skip certain messages. Options include #{VALID_MESSAGES.join(',')}"
      # TODO Reformat this in columns: tape shard match loc1 value1 loc2 value2
      def check_original
        archive = Archive.new(options[:archive])
        exclusions = (options[:exclude] || '').split(/\s*[,\s]\s*/).map{|s| s.strip.downcase }
        inclusions = (options[:include] || VALID_MESSAGES.join(',')).split(/\s*[,\s]\s*/).map{|s| s.strip.downcase }
        table = []
        table << %w{Tape Shard Message Source\ 1 Value\ 1 Source\ 2 Value\ 2}
        archive.each do |tape|
          tape_spec = archive.original_index.find {|spec| spec[:tape] == tape }
          unless tape_spec
            table << [tape, '', "No entry in index"] if inclusions.include?('missing') && !exclusions.include?('missing')
            next
          end
          file_descriptor = archive.descriptor(tape, :build=>options[:build])
          if File.relative_path(tape_spec[:file]) != file_descriptor[:path] && inclusions.include?('name') && !exclusions.include?('name')
            table << [tape, '', "Names don't match", "Index", tape_spec[:file], 'File', file_descriptor[:path]]
          end
          if file_descriptor[:file_type] == :frozen
            index_date = tape_spec[:date]
            tape_date = file_descriptor[:file_date]
            case index_date <=> tape_date
            when -1 
              table << [tape, '', "Older date in index", 'Index', index_date.strftime(DATE_FORMAT), 
                                                         'File',  tape_date.strftime(DATE_FORMAT)] \
                                                              if inclusions.include?('old') &&!exclusions.include?('old')
            when 1
              table << [tape, '', "Newer date in index", 'Index', index_date.strftime(DATE_FORMAT), 
                                                         'File',  tape_date.strftime(DATE_FORMAT)] \
                                                              if inclusions.include?('new') &&!exclusions.include?('new')
            end
            file_descriptor[:shard_count].times do |i|
              descriptor = file_descriptor[:shards][i]
              shard_date = descriptor[:shard_date]
              shard = descriptor[:name]
              case index_date <=> shard_date
              when -1 
                table << [tape, shard, "Older date in index", 'Index', index_date.strftime(DATE_FORMAT), 
                                                              'Shard', shard_date.strftime(DATE_FORMAT)] \
                                                                if inclusions.include?('old_file') &&!exclusions.include?('old_file')
              when 1
                table << [tape, shard, "Newer date in index", 'Index', index_date.strftime(DATE_FORMAT), 
                                                              'Shard', shard_date.strftime(DATE_FORMAT)] \
                                                                if inclusions.include?('new_file') &&!exclusions.include?('new_file')
              end
              case tape_date <=> shard_date
              when -1 
                table << [tape, shard, "Older date in file", 'File',   tape_date.strftime(DATE_FORMAT), 
                                                              'Shard', shard_date.strftime(DATE_FORMAT)] \
                                                                if inclusions.include?('old_file') &&!exclusions.include?('old_file')
              when 1
                table << [tape, shard, "Newer date in file", 'File',   tape_date.strftime(DATE_FORMAT), 
                                                              'Shard', shard_date.strftime(DATE_FORMAT)] \
                                                                if inclusions.include?('new_file') &&!exclusions.include?('new_file')
              end
            end
          end
        end
        if table.size <= 1
          puts "No messages"
        else
          puts table.justify_rows.map{|row| row.join('  ')}.join("\n")
        end
      end
    end
  end
end