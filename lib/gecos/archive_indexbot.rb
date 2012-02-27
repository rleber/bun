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
      
      # TODO Create check method: Check that an index file entry exists for each tape
      # file, check frozen file dates and content vs. index, check 
      # normal archive file contents vs. index
      desc "check", "Check contents of the index"
      option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
      def check
        archive = Archive.new(options[:archive])
        tapes = archive.tapes
        tapes.each do |tape|
          tape_spec = archive.index.find {|spec| spec[:tape] == tape }
          puts "No index entry for #{tape}" unless tape_spec
        end
      end
    end
  end
end