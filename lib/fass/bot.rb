require 'thor'
require 'ember'
require 'fass/rtf'
require 'fass/script'
require 'fass/clean'
require 'mechanize'
require 'fileutils'
require 'fass/archive'
require 'fass/decoder'
require 'fass/defroster'
require 'fass/freezerbot'
require 'fass/dump'

class Fass
  class Bot < Thor
    
    SCRIPTS_DIRECTORY = 'scripts'
    
    no_tasks do
      def fix_script_file(file, *exts)
        exts = ['.script'] if exts.size == 0
        file = file.dup
        file = "#{SCRIPTS_DIRECTORY}/#{file}" unless file =~ %r{^/} || file =~ /^#{Regexp.escape(SCRIPTS_DIRECTORY)}\/[^\/]*$/
        return file if File.exists?(file)
        exts.each do |ext|
          next if ext.nil?  # Special case -- allows you to specify NO substitutions: fix_script_file(file, nil)
          ext = '.' + ext unless ext =~ /^\./
          f2 = file + ext
          return f2 if File.exists?(f2)
        end
        file  # If no file exists, return the original file, plus the directory (if any)
      end

      # Write text to the file, unless file == '-', in which case, write to STDOUT
      def write_file(file_name, text)
        if file_name == '-'
          puts text
        else
          File.open(file_name, 'w') {|f| f.write(text)}
        end
      end
    end
    
    desc "describe", "Describe the scripting language"
    def describe
      puts File.read("doc/script_format_extended.text")
    end
    
    # TODO Add "as performed/as written" flag
    # TODO Add "with notes" flag
    desc 'render FILE', "Render a script file"
    def render(file)
      file = fix_script_file(file)
      abort "Script file #{file} does not exist" unless File.exists?(file)
      script = Script.new(File.read(file))
      script.source_file = file
      puts script.render
    end

    desc "rtf INPUT_FILE [OUTPUT_FILE]", "Read a script from an RTF format file"
    long_desc "Output is to <input_file>.raw.txt if none is specified, or to STDOUT if it is \"-\""
    def rtf(input_file, output_file=nil)
      input_file = fix_script_file(input_file, '.rtf')
      abort "Script input_file #{input_file} does not exist" unless File.exists?(input_file)
      output_file = input_file.sub(/\.rtf+$/, '.raw.txt') unless output_file
      parser = RTF::Parser.new(File.read(input_file))
      write_file output_file, parser.text
    end
    
    desc "clean1 INPUT_FILE [OUTPUT_FILE]", "Clean an extracted text file (first pass)"
    long_desc "Output is to <input_file>.clean1.txt if none is specified, or to STDOUT if it is \"-\""
    def clean1(input_file, output_file=nil)
      input_file = fix_script_file(input_file, '.raw.txt', '.txt')
      abort "Script input_file #{input_file} does not exist" unless File.exists?(input_file)
      output_file = input_file.sub(/(\.raw|\.txt)+$/, '.clean1.txt') unless output_file
      cleaner = Fass::Script::Cleaner.new(File.read(input_file))
      write_file output_file, cleaner.clean1
      warn "Please mark the end of each song with \"END OF SONG\" line."
    end
    
    desc "clean2 INPUT_FILE [OUTPUT_FILE]", "Clean an extracted text file (Second pass)"
    long_desc "Output is to <input_file>.clean.txt if none is specified, or to STDOUT if it is \"-\""
    def clean2(input_file, output_file=nil)
      input_file = fix_script_file(input_file, '.clean1.txt', '.txt')
      abort "Script input_file #{input_file} does not exist" unless File.exists?(input_file)
      output_file = input_file.sub(/(\.raw|\.txt|\.clean|\.clean1)+$/, '.clean.txt') unless output_file
      input_file = fix_script_file(input_file, 'rtf')
      cleaner = Fass::Script::Cleaner.new(File.read(input_file))
      write_file output_file, cleaner.clean2
    end
    
    # TODO Move this to tools project; refactor
    no_tasks do
      def fetch(base_uri, destination)
        count = 0
        agent = Mechanize.new
        FileUtils::rm_rf(destination)
        process(agent, base_uri) do |page|
          relative_uri = page.uri.path.sub(/^#{Regexp.escape(base_uri)}/, '')
          file_name = destination + relative_uri
          dirname = File.dirname(file_name)
          FileUtils::mkdir_p(dirname)
          File.open(file_name, 'w') {|f| f.write page.body}
          count += 1
        end
        puts "#{count} files retrieved"
      end
      
      def process(parent, item, &blk)
        uri = uri(parent, item)
        page = get(parent, item)
        if uri =~ /\/$/ # It's a directory; fetch it
          page.links.each do |link|
            next if IGNORE_LINKS.include?(link.text)
            next if link.href =~ /^mailto:/i
            process(page, link, &blk)
          end
        else # It's a leaf (page); process it
          yield page
        end
      end

      def uri(parent, item)
        case parent
        when Mechanize::Page
          base_uri = parent.uri
          raise "Unexpected link item from page #{item.inspect}" unless item.is_a?(Mechanize::Page::Link)
          sub_uri = item.href
          (base_uri + sub_uri).path
        when Mechanize
          item
        else
          raise "Unknown parent type #{parent.inspect}"
        end
      end
      
      def get(parent, item)
        case parent
        when Mechanize::Page
          raise "Unexpected link item from page #{item.inspect}" unless item.is_a?(Mechanize::Page::Link)
          item.click
        when Mechanize
          parent.get(item)
        else
          raise "Unknown parent type #{parent.inspect}"
        end
      end
    end
    
    IGNORE_LINKS = ["Name", "Last modified", "Size", "Description", "Parent Directory"]
    desc "idallen", "Fetch files from Ian! Allen's online repository"
    def idallen
      agent = Mechanize.new
      fetch("http://idallen.com/fass/honeywell_archiver/", "data/idallen.com")
    end
    
    option "lines", :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
    option "frozen", :aliases=>'-f', :type=>'boolean', :desc=>'Display characters in frozen format (i.e. 5 per word)'
    option "offset", :aliases=>'-o', :type=>'numeric', :desc=>'Skip the first n lines'
    desc "dump FILE", "Dump a Honeywell file"
    def dump(file)
      file = Archive.default_directory + '/' + file unless file =~ /\//
      decoder = Fass::Decoder.new(File.read(file))
      archived_file = Archive.file_name(file)
      archived_file = "--unknown--" unless archived_file
      puts "Archive for file #{archived_file}:"
      words = decoder.words
      Dump.dump(words, options)
    end

    register Fass::FreezerBot, :freezer, "freezer", "Manage frozen Honeywell files"
  end
end