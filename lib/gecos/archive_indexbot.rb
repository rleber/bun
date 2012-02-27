class GECOS
  class Archive
    class IndexBot < Thor
      desc "ls", "List the index file for the archive"
      def ls
        archive = Archive.new
        # TODO Use Array.justify_rows
        archive.index.each do |spec|
          puts "#{spec[:tape]}  #{spec[:date].strftime('%Y/%d/%m')}  #{spec[:file]}"
        end
      end
    end
  end
end