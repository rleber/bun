require 'thor'
require 'mechanize'
require 'fileutils'
require 'gecos/archive'
require 'gecos/decoder'
require 'gecos/defroster'
require 'gecos/archivebot'
require 'gecos/freezerbot'
require 'gecos/dump'

class GECOS
  class Bot < Thor
    
    desc "readme", "Display helpful information for beginners"
    def readme
      STDOUT.write File.read("doc/readme.md")
    end
    
    option "lines", :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
    option "frozen", :aliases=>'-f', :type=>'boolean', :desc=>'Display characters in frozen format (i.e. 5 per word)'
    option "escape", :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
    option "offset", :aliases=>'-o', :type=>'numeric', :desc=>'Skip the first n lines'
    desc "dump FILE", "Dump a Honeywell file"
    def dump(file)
      archive = Archive.new
      file = archive.expanded_tape_path(file)
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
    option "warn", :aliases=>'-w', :type=>'boolean', :desc=>"Warn if there are decoding errors"
    option "log", :aliases=>'-l', :type=>'string', :desc=>"Log status to specified file"
    desc "unpack FILE [TO]", "Unpack a file (Not frozen files -- use freezer subcommands for that)"
    def unpack(file, to=nil)
      archive = Archive.new
      expanded_file = archive.expanded_tape_path(file)
      decoder = GECOS::Decoder.new(File.read(expanded_file))
      archived_file = archive.file_path(expanded_file)
      abort "Can't unpack #{file}. It contains a frozen file: #{archived_file}" if Archive.frozen?(expanded_file)
      content = decoder.content
      shell = Shell.new
      shell.write to, content
      warn "Unpacked with #{decoder.errors} errors" if options[:warn] && decoder.errors > 0
      shell.log options[:log], "unpack #{to.inspect} from #{file.inspect} with #{decoder.errors} errors" if options[:log]
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
      tape_path = archive.expanded_tape_path(file)
      decoder = GECOS::Decoder.new(File.read(tape_path))
      archived_file = archive.file_path(tape_path)
      archive_name = decoder.file_archive_name
      subdirectory = decoder.file_subdirectory
      specification = decoder.file_specification
      description = decoder.file_description
      name = decoder.file_name
      path = decoder.file_path
      description = decoder.file_description
      archival_date = archive.archival_date(file)
      archival_date_display = archival_date ? archival_date.strftime('%Y/%m/%d') : "n/a"
      frozen = Archive.frozen?(tape_path)
      frozen_files = Defroster.new(decoder).file_names.sort if frozen
      puts "Tape             #{file}"
      puts "Tape path        #{tape_path}"
      puts "Archived file    #{path}"
      puts "Archive          #{archive_name}"
      puts "Subdirectory     #{subdirectory}"
      puts "Name             #{name}"
      puts "Description      #{description}"
      puts "Specification    #{specification}"
      puts "Archival date:   #{archival_date_display}"
      puts "Type:            #{frozen ? 'Frozen' : 'Normal'}"
      puts "Frozen files:    #{frozen_files.join(', ')}" if frozen
    end

    register GECOS::FreezerBot, :freezer, "freezer", "Manage frozen Honeywell files"
    register GECOS::ArchiveBot, :archive, "archive", "Manage archives of Honeywell files"
  end
end