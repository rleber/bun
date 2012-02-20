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
require 'rleber-interaction'

class Fass
  class Bot < Thor
    include Interaction
    
    SCRIPTS_DIRECTORY = 'scripts'
    
    desc "readme", "Display helpful information for beginners"
    def readme
      STDOUT.write File.read("doc/readme.md")
    end
    
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
      # Fetch all files and subdirectories of a uri to a destination folder
      # The destination folder will have subfolders created, based on the structure of the uri
      # For example, fetching "http://example.com/in/a/directory/" to "data" will create a
      # copy of the contents at the uri into "data/example.com/in/a/directory"
      def _fetch(base_uri, destination)
        destination.sub!(/\/$/,'') # Remove trailing slash from destination, if any
        destination = destination + '/' + base_uri.sub(/^http:\/\//,'')
        destination.sub!(/\/$/,'') # Remove trailing slash from destination, if any
        uri_sub_path = base_uri.sub(/http:\/\/[^\/]*/,'')
        count = 0
        agent = Mechanize.new
        FileUtils::rm_rf(destination)
        process(agent, base_uri) do |page|
          relative_uri = page.uri.path.sub(/^#{Regexp.escape(uri_sub_path)}/, '')
          file_name = destination + '/' + relative_uri
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
    desc "fetch [URL]", "Fetch files from an online repository"
    long_desc <<-EOT
Fetches all the files and subdirectories of the specified online url to the data directory.

Fetched files are copied to subdirectories of the data directory. So, for instance, fetching
"http://example.com/in/a/subdirectory/" will cause files to be copied to the directory
data/example.com/in/a/subdirectory and its subdirectories, mirroring the structure online.

If no URL is provided, this command will use the location specified in the FASS_ARCHIVE_URL
environment variable. If this environment variable is not set, the URL is mandatory.
    EOT
    def fetch(url=nil)
      agent = Mechanize.new
      url ||= ENV["FASS_ARCHIVE_URL"]
      abort "No url provided" unless url
      _fetch(url, "data")
    end
    
    option "lines", :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
    option "frozen", :aliases=>'-f', :type=>'boolean', :desc=>'Display characters in frozen format (i.e. 5 per word)'
    option "escape", :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
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
    
    FILE_CONTENT_OFFSET = 11
    option "inspect", :aliases=>'-i', :type=>'boolean', :desc=>"Display long format details for each line"
    option "deleted", :aliases=>'-d', :type=>'boolean', :desc=>"Display deleted lines (only with --inspect)"
    desc "unpack", "Unpack a file (Not frozen files -- use freezer subcommands for that)"
    def unpack(file)
      file = Archive.default_directory + '/' + file unless file =~ /\//
      decoder = Fass::Decoder.new(File.read(file))
      archived_file = Archive.file_name(file)
      abort "Can't unpack file. It's a frozen file #{archived_file}" if Archive.frozen?(file)
      words = decoder.words
      
      offset = FILE_CONTENT_OFFSET
      loop do # look for a nul ending the file description
        break if offset > words.size
        word = words[offset]
        chs = ('%012o'%word).scan(/.{3}/)
        break if chs.include?('000')
        offset += 1
      end
      # Skip forward
      offset += 2
      offset_width = ('%o'%(words.size)).size
      line_count = 0
      loop do
        break if offset >= words.size
        break if words[offset] == 0170000
        line_length = (words[offset] & 0xffffc0000) >> 18
        lower_bits = words[offset] & 0x3ffff
        if line_length > 0x1ff # Deleted text; look for a word starting in 0x000 in the upper 9 bits
          original_offset = offset
          loop do
            offset += 1
            break if offset >= words.size
            # puts '%012o'%(words[offset]) + ':' + '%012o'%(words[offset] & 0xff1000000)
            if (words[offset] & 0xff1000000) == 0
              if options[:inspect] && options[:deleted]
                line = decoder.characters[(original_offset+1)*decoder.characters_per_word...offset*decoder.characters_per_word].sub(/\x7f*$/,'')
                puts %Q{0#{"%0#{offset_width}o"%original_offset} #{'%012o'%words[original_offset]} #{'%06o'%line_length} #{'%06o'%lower_bits} D #{line.inspect[1..-2]}}
              end
              offset += 1
              break
            end
          end
        else
          if line_count > 0 # Skip the first line; it's always nulls
            line = decoder.characters[(offset+1)*decoder.characters_per_word, line_length*decoder.characters_per_word].sub(/\x7f*$/,'')
            if options[:inspect]
              puts %Q{0#{"%0#{offset_width}o"%offset} #{'%012o'%words[offset]} #{'%06o'%line_length} #{'%06o'%lower_bits}   #{line.inspect[1..-2]}}
            else
              puts line
            end
          end
          line_count += 1
          offset += line_length+1
        end
      end
    end

    option "inspect", :aliases=>'-i', :type=>'boolean', :desc=>"Display long format details for each line"
    desc "repair FILE TO", "Repair a file (Not frozen files -- use freezer subcommands for that)"
    def repair(file, to)
      file = Archive.default_directory + '/' + file unless file =~ /\//
      decoder = Fass::Decoder.new(File.read(file))
      archived_file = Archive.file_name(file)
      abort "Can't unpack file. It's a frozen file #{archived_file}" if Archive.frozen?(file)
      content = decoder.words
      lines = nil
      loop do
        lines = []
        offset = FILE_CONTENT_OFFSET
        d = Decoder.new(nil)
        d.words = content
        loop do
          break if offset >= content.size
          line_length = (content[offset] & 0xffffc0000) >> 18
          lower_bits = content[offset] & 0x3ffff
          line = d.characters[(offset+1)*d.characters_per_word, line_length*d.characters_per_word].sub(/\x7f*$/,'')
          lines << {:offset=>offset, :content=>line}
          offset += line_length+1
        end
        flawed_line = lines.find {|l| l[:content].gsub(/\t/,' ') =~ /[[:cntrl:]]/}
        break unless flawed_line
        flaw_location = flawed_line[:content].gsub(/\t/,' ').sub(/[[:cntrl:]].*/m, '').size
        puts "Found a suspect line at #{'%o' % flawed_line[:offset]}: #{flawed_line[:content][0, flaw_location+5+1].inspect}"
        d1 = Decoder.new(nil)
        d1.words = content[flawed_line[:offset]..-1]
        remaining_characters = d1.characters
        search_start = flaw_location
        limit = nil
        start_location = nil
        end_location = nil
        next_line_end = nil
        from_text = nil
        to_text = nil
        loop do
          loop do
            if remaining_characters[(search_start+4)..-1] =~ /(\x7f+)|([[:cntrl:]])/m # +4 for the line length and flag characters
              last_line_end = $`.size
              limit = (search_start + last_line_end + 1 + 15)/16 + 1 # Final +1 to show an extra line of context
            else
              abort "Unable to find a later line ending."
            end
            Dump.dump(content, :offset=>flawed_line[:offset], :lines=>limit)
            break unless get_logical("Need to see more? ", :prompt_on=>STDERR)
            search_start += last_line_end + 1
          end
          clipped_section = content[flawed_line[:offset], limit*4]
          d = Decoder.new(nil)
          d.words = clipped_section
          chars = d.characters
          start_location = nil
          loop do
            start_clip = Regexp.new(get_prompted("Clip from (regex) ", :prompt_on=>STDERR))
            start_location = chars =~ start_clip
            if start_location
              start_location += $&.length
              break
            end
            STDERR.puts "That does not match the text. Please try again."
          end
          end_location = nil
          loop do
            end_clip = Regexp.new(get_prompted("Clip to (regex) ", :prompt_on=>STDERR))
            end_location = chars =~ end_clip
            break if end_location
            STDERR.puts "That does not match the text. Please try again."
          end
          next_line_end = remaining_characters[end_location..-1] =~ /(\x7f+)|([[:cntrl:]])/m 
          abort "Can't find the end of the clipped line" unless next_line_end
          next_line_end += end_location + ($1||"").size - 1
          from_text = remaining_characters[4..next_line_end]
          STDERR.puts "from text: #{from_text.inspect}"
          to_text = (remaining_characters[4...(start_location+4)] + remaining_characters[end_location, next_line_end+1 - end_location]).sub(/\x7f+$/,'')
          STDERR.puts "Line after clipping:  #{to_text.inspect}"
          break if get_logical("Is this correct? ", :prompt_on=>STDERR)
        end
        if to_text.size%4 != 0
          to_text = to_text + "\x7f"*(4-to_text.size%4)
        end
        before_words = ((4+from_text.size)+3)/4
        after_words = ((4+to_text.size)+3)/4
        packed_line = [(to_text.size/4) << 18]
        chs = 4
        to_text.unpack('C*').each do |c|
          if chs >= 4
            packed_line << 0
            chs = 0
          end
          packed_line[-1] = (packed_line[-1]<<9) + (c & 0x1ff)
          chs += 1
        end
        content[flawed_line[:offset], before_words] = packed_line
        decoder.words = content
      end
      File.open(to,'w') {|f| f.write lines.map{|l| lines[:content]}.join("\n") }
    end
    
    desc "index", "Display an index of archived files"
    def index
    end

    register Fass::FreezerBot, :freezer, "freezer", "Manage frozen Honeywell files (Type \"fass freezer\" for more details)"
  end
end