require 'fass/archive'

class Fass

  class FreezerBot < Thor

    option "long", :aliases=>'-l', :type=>'boolean', :desc=>"Display listing in long format"
    desc "ls FILE", "List contents of a frozen Honeywell file"
    def ls(file)
      file = Archive.default_directory + '/' + file unless file =~ /\//
      archived_file = Archive.file_name(file)
      archived_file = "--unknown--" unless archived_file
      abort "File #{file} is an archive of #{archived_file}, which is not frozen." unless Archive.frozen?(file)
      decoder = Fass::Decoder.new(File.read(file))
      # puts "Archive for file #{archived_file}:"
      defroster = Fass::Defroster.new(decoder)
      # puts "Last updated on #{defroster.update_date}"
      # puts "Contains #{defroster.files} files"
      puts "    File     Updated       Words     Blocks     Offset"
      defroster.files.times do |i|
        descr = defroster.descriptor(i)
        if options[:long]
          puts "#{'%3d'%i} #{'%-8s'%descr.file_name} #{descr.update_date} #{'%10d'%descr.file_words} #{'%10d'%descr.file_blocks} #{'%10d'%descr.file_start}"
        else
          puts descr.file_name
        end
      end
    end
    
    no_tasks do
      def index_for(defroster, n)
        if n.to_s !~ /^\d+$/
          name = n
          n = defroster.file_index(name)
          abort "Frozen file does not contain a file #{name}" unless n
        else
          n = n.to_i
          abort "Frozen file does not contain file number #{n}" if n<1 || n>defroster.files
          n -= 1
        end
        n
      end
    end

    desc "thaw FILE FILE_NAME_OR_NUMBER", "Uncompress a frozen Honeywell file"
    def thaw(file, n)
      limit = options[:lines]
      file = Archive.default_directory + '/' + file unless file =~ /\//
      archived_file = Archive.file_name(file)
      archived_file = "--unknown--" unless archived_file
      abort "File #{file} is an archive of #{archived_file}, which is not frozen." unless Archive.frozen?(file)
      decoder = Fass::Decoder.new(File.read(file))
      defroster = Fass::Defroster.new(decoder)
      STDOUT.write defroster.content(index_for(defroster, n))
    end

    option "lines", :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
    option "offset", :aliases=>'-o', :type=>'numeric', :desc=>'Skip the first n lines'
    desc "dump FILE FILE_NAME_OR_NUMBER", "Uncompress a frozen Honeywell file"
    def dump(file, n)
      limit = options[:lines]
      file = Archive.default_directory + '/' + file unless file =~ /\//
      archived_file = Archive.file_name(file)
      archived_file = "--unknown--" unless archived_file
      abort "File #{file} is an archive of #{archived_file}, which is not frozen." unless Archive.frozen?(file)
      decoder = Fass::Decoder.new(File.read(file))
      defroster = Fass::Defroster.new(decoder)
      file_index = index_for(defroster, n)
      content = defroster.file_words(file_index)
      puts "Archive for file #{defroster.file_name(file_index)}:"
      Dump.dump(content, options.merge(:frozen=>true))
    end
  end
end
