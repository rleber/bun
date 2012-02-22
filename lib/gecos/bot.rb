require 'thor'
require 'mechanize'
require 'fileutils'
require 'gecos/archive'
require 'gecos/decoder'
require 'gecos/defroster'
require 'gecos/archivebot'
require 'gecos/freezerbot'
require 'gecos/dump'
require 'rleber-interaction'

class GECOS
  class Bot < Thor
    include Interaction
    
    desc "readme", "Display helpful information for beginners"
    def readme
      STDOUT.write File.read("doc/readme.md")
    end
    
    no_tasks do
      # Write text to the file, unless file == '-', in which case, write to STDOUT
      def write_file(file_name, text)
        if file_name == '-'
          puts text
        else
          File.open(file_name, 'w') {|f| f.write(text)}
        end
      end
    end
    
    option "lines", :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
    option "frozen", :aliases=>'-f', :type=>'boolean', :desc=>'Display characters in frozen format (i.e. 5 per word)'
    option "escape", :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
    option "offset", :aliases=>'-o', :type=>'numeric', :desc=>'Skip the first n lines'
    desc "dump FILE", "Dump a Honeywell file"
    def dump(file)
      archive = Archive.new
      file = archive.qualified_tape_file_name(file)
      decoder = GECOS::Decoder.new(File.read(file))
      archived_file = archive.file_path(file)
      archived_file = "--unknown--" unless archived_file
      puts "Archive for file #{archived_file}:"
      words = decoder.words
      Dump.dump(words, options)
    end
    
    UNPACK_OFFSET = 22
    option "inspect", :aliases=>'-i', :type=>'boolean', :desc=>"Display long format details for each line"
    option "deleted", :aliases=>'-d', :type=>'boolean', :desc=>"Display deleted lines (only with --inspect)"
    desc "unpack", "Unpack a file (Not frozen files -- use freezer subcommands for that)"
    def unpack(file)
      archive = Archive.new
      file = archive.qualified_tape_file_name(file)
      decoder = GECOS::Decoder.new(File.read(file))
      archived_file = archive.file_path(file)
      abort "Can't unpack file. It's a frozen file #{archived_file}" if Archive.frozen?(file)
      STDOUT.write decoder.content
    end
    
    no_tasks do
      def clean_file?(file)
        Decoder.clean? File.read(file)
      end
    end
    
    desc "test FILE", "Test a file for cleanness -- i.e. does it contain non-printable characters?"
    def test(file)
      if clean_file?(file)
        puts "File is clean"
      else
        puts "File is dirty"
      end
    end
    
    desc "describe FILE", "Display description information for a file"
    def describe(file)
      archive = Archive.new
      file = archive.qualified_tape_file_name(file)
      decoder = GECOS::Decoder.new(File.read(file))
      archived_file = archive.file_path(file)
      archive = decoder.file_archive_name
      subdirectory = decoder.file_subdirectory
      specification = decoder.file_specification
      description = decoder.file_description
      name = decoder.file_name
      path = decoder.file_path
      description = decoder.file_description
      frozen = Archive.frozen?(file)
      puts "Path             #{path}"
      puts "Archive          #{archive}"
      puts "Subdirectory     #{subdirectory}"
      puts "Name             #{name}"
      puts "Description      #{description}"
      puts "Specification    #{specification}"
      puts "Type:            #{frozen ? 'Frozen' : 'Normal'}"
    end

    register GECOS::FreezerBot, :freezer, "freezer", "Manage frozen Honeywell files"
    register GECOS::ArchiveBot, :archive, "archive", "Manage archives of Honeywell files"
  end
end