require 'thor'
require 'ember'
require 'fass/rtf'
require 'fass/script'
require 'fass/clean'
require 'net/http'

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
    
    desc "idallen", "Fetch files from Ian! Allen's online repository"
    def idallen
      Net::HTTP.start("idallen.com") do |http|
        response = http.get('/fass/honeywell_archiver/')
        puts "Code = #{response.code}"
        puts "Message = #{response.message}"
        puts response.body
      end
    end
  end
end