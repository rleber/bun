class GECOS
  class Archive
    class IndexBot < Thor
      desc "ls", "List the index file for the archive"
      option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
      def ls
        archive = Archive.new(options[:archive])
        # TODO Use Array.justify_rows
        archive.index.each do |spec|
          puts "#{spec[:tape]}  #{spec[:date].strftime('%Y/%d/%m')}  #{spec[:file]}"
        end
      end
      
      desc "set_dates", "Set file modification dates for archived files, based on index"
      option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
      def set_dates
        archive = Archive.new(options[:archive])
        shell = GECOS::Shell.new
        archive.index.each do |spec|
          file = archive.expanded_tape_path(spec[:tape])
          timestamp = spec[:date]
          puts "About to set timestamp: #{file} #{timestamp.strftime('%Y/%m/%d %H:%M:%S')}"
          exit
          shell.set_timestamp(file, timestamp)
        end
      end
      
      VALID_MESSAGES = %w{missing name old new old_file new_file}
      
      # TODO Create check method: Check that an index file entry exists for each tape
      # file, check frozen file dates and content vs. index, check 
      # text archive file contents vs. index
      desc "check", "Check contents of the index"
      option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
      option "include", :aliases=>'-i', :type=>'string', :desc=>"Include only certain messages. Options include #{VALID_MESSAGES.join(',')}"
      option "exclude", :aliases=>'-x', :type=>'string', :desc=>"Skip certain messages. Options include #{VALID_MESSAGES.join(',')}"
      def check
        archive = Archive.new(options[:archive])
        exclusions = (options[:exclude] || '').split(/\s*[,\s]\s*/).map{|s| s.strip.downcase }
        inclusions = (options[:include] || VALID_MESSAGES.join(',')).split(/\s*[,\s]\s*/).map{|s| s.strip.downcase }
        tapes = archive.tapes
        tapes.each do |tape|
          tape_spec = archive.index.find {|spec| spec[:tape] == tape }
          tape_path = archive.expanded_tape_path(tape)
          unless tape_spec
            puts "No index entry for #{tape}" if inclusions.include?('missing') && !exclusions.include?('missing')
            next
          end
          file = File::Text.open(tape_path)
          if tape_spec[:file] != file.unexpanded_file_path && inclusions.include?('name') && !exclusions.include?('name')
            puts "#{tape}: File name in index (#{tape_spec[:file].inspect}) doesn't match contents of file (#{file.unexpanded_file_path.inspect})"
          end
          frozen = File.frozen?(tape_path)
          if frozen
            # TODO Is duplicate open necessary?
            defroster = Defroster.new(File.open(tape_path))
            case tape_spec[:date] <=> defroster.update_date
            when -1 
              puts "#{tape}: Archival date in index (#{tape_spec[:date].strftime('%Y/%m/%d')}) is older than date of frozen archive (#{defroster.update_date.strftime('%Y/%m/%d')})" \
                if inclusions.include?('old') &&!exclusions.include?('old')
            when 1
              puts "#{tape}: Archival date in index (#{tape_spec[:date].strftime('%Y/%m/%d')}) is newer than date of frozen archive (#{defroster.update_date.strftime('%Y/%m/%d')})" \
              if inclusions.include?('new') &&!exclusions.include?('new')
            end
            defroster.files.times do |i|
              descriptor = defroster.descriptor(i)
              file_date = descriptor.update_date
              frozen_file = descriptor.file_name
              case tape_spec[:date] <=> file_date
              when -1 
                puts "#{tape}: Archival date in index (#{tape_spec[:date].strftime('%Y/%m/%d')}) is older than date of frozen file #{frozen_file} (#{file_date.strftime('%Y/%m/%d')})" \
                  if inclusions.include?('old_file') &&!exclusions.include?('old_file')
              when 1
                puts "#{tape}: Archival date in index (#{tape_spec[:date].strftime('%Y/%m/%d')}) is newer than date of frozen file #{frozen_file} (#{file_date.strftime('%Y/%m/%d')})" \
                  if inclusions.include?('new_file') &&!exclusions.include?('new_file')
              end
              case defroster.update_date <=> defroster.update_date
              when -1 
                puts "#{tape}: Archival date of archive (#{defroster.update_date.strftime('%Y/%m/%d')}) is older than date of frozen file #{frozen_file} (#{file_date.strftime('%Y/%m/%d')})" \
                  if inclusions.include?('old_file') &&!exclusions.include?('old_file')
              when 1
                puts "#{tape}: Archival date of archive (#{defroster.update_date.strftime('%Y/%m/%d')}) is newer than date of frozen file #{frozen_file} (#{file_date.strftime('%Y/%m/%d')})" \
                  if inclusions.include?('new_file') &&!exclusions.include?('new_file')
              end
            end
          end
        end
      end
    end
  end
end