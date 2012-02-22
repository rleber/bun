require 'thor'
require 'mechanize'
require 'fileutils'
require 'gecos/archive'

class GECOS
  class ArchiveBot < Thor
    
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
          if @dryrun
            puts "Fetch #{file_name}"
          else
            FileUtils::mkdir_p(dirname)
            File.open(file_name, 'w') {|f| f.write page.body}
          end
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
    desc "fetch [URL] [TO]", "Fetch files from an online repository"
    option 'dryrun', :aliases=>'-d', :type=>'boolean', :desc=>"Do a dry run only; show what would be fetched, but don't save it"
    long_desc <<-EOT
Fetches all the files and subdirectories of the specified online url to the data directory.

Fetched files are copied to subdirectories of the data directory. So, for instance, fetching
"http://example.com/in/a/subdirectory/" will cause files to be copied to the directory
data/example.com/in/a/subdirectory and its subdirectories, mirroring the structure online.

If no URL is provided, this command will use the location specified in the data/archive_config.yml
file or the GECOS_REPOSITORY environment variable. If neither is set, the URL is mandatory.

If no "to" location is provided, this command will use the archive location specified in
data/archive_config.yml. Usually, this is ~/gecos_archive
    EOT
    def fetch(url=nil, archive_location=nil)
      agent = Mechanize.new
      url ||= Archive.repository
      archive_location  ||= Archive.location
      abort "No url provided" unless url
      abort "No archive location provided" unless archive_location
      @dryrun = options[:dryrun]
      _fetch(url, archive_location)
    end
    
    no_tasks do
      def get_regexp(pattern)
        Regexp.new(pattern)
      rescue
        nil
      end
    end
    
    SORT_VALUES = %w{tape file type}
    TYPE_VALUES = %w{all frozen normal}
    desc "ls [ARCHIVE]", "Display an index of archived files"
    option "long", :aliases=>"-l", :type=>'boolean', :desc=>"Display long format (incl. normal vs. frozen)"
    option "sort", :aliases=>"-s", :type=>'string', :default=>SORT_VALUES.first, :desc=>"Sort order for files (#{SORT_VALUES.join(', ')})"
    option "type", :aliases=>"-T", :type=>'string', :default=>TYPE_VALUES.first, :desc=>"Show only files of this type (#{TYPE_VALUES.join(', ')})"
    option "tapes", :aliases=>"-t", :type=>'string', :default=>'.*', :desc=>"Show only tapes that match this Ruby Regexp, e.g. 'f.*oo\\.rb$'"
    option "files", :aliases=>"-f", :type=>'string', :default=>'.*', :desc=>"Show only files that match this Ruby Regexp, e.g. 'f.*oo\\.rb$'"
    def ls(archive_location=nil)
      abort "Unknown --sort setting. Must be one of #{SORT_VALUES.join(', ')}" unless SORT_VALUES.include?(options[:sort])
      abort "Unknown --type setting. Must be one of #{TYPE_VALUES.join(', ')}" unless TYPE_VALUES.include?(options[:type])
      type_pattern = options[:type]=='all' ? /.*/ : /^#{Regexp.escape(options[:type])}$/i
      file_pattern = get_regexp(options[:files])
      abort "Invalid --files pattern. Should be a valid Ruby regular expression (except for the delimiters)" unless file_pattern
      tape_pattern = get_regexp(options[:tapes])
      abort "Invalid --tapes pattern. Should be a valid Ruby regular expression (except for the delimiters)" unless tape_pattern
      archive = Archive.new(archive_location)
      ix = archive.tapes
      directory = archive.location
      puts "Archive at #{directory}:"
      tape_name_width = ix.map{|entry| entry.first.size}.max
      if options[:long]
        puts "%-#{tape_name_width}s" % 'Tape' + '  Type    File'
      else
        puts "%-#{tape_name_width}s" % 'Tape' + '  File'
      end
      # Retrieve file information
      file_info = []
      ix.each_with_index do |tape_name, i|
        file_name = archive.file_path(tape_name)
        friz = Archive.frozen?(archive.qualified_tape_file_name(tape_name)) ? 'Frozen' : 'Normal'
        next unless friz =~ type_pattern && tape_name=~tape_pattern && file_name=~file_pattern
        file_info << {'tape'=>tape_name, 'type'=>friz, 'file'=>file_name}
      end
      sorted_info = file_info.sort_by{|fi| [fi[options[:sort]], fi['file'], fi['tape']]} # Sort it in order
      # Display it
      sorted_info.each do |entry|
        typ = options[:long] ? '%-8s'% entry['type'] : ""
        puts %Q{#{"%-#{tape_name_width}s" % entry['tape']}  #{typ}#{'%-s' % entry['file']}}
      end
    end
    
    no_tasks do
      def ex(task)
        warn task
        system(task) unless @dryrun
      end
      
      def shell_quote(f)
        f.inspect
      end
    end
    
    desc "extract [ARCHIVE] [TO]", "Extract all the files in the archive"
    option 'dryrun', :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually extract"
    def extract(archive_location=nil, to=nil)
      @dryrun = options[:dryrun]
      directory = archive_location || Archive.location
      archive = Archive.new(directory)
      to ||= File.join(archive.location, archive.extract_directory)
      ix = archive.tapes
      ex "rm -rf #{to}"
      ix.each do |tape_name|
        extended_file_name = archive.qualified_tape_file_name(tape_name)
        frozen = Archive.frozen?(extended_file_name)
        decoder = Decoder.new(File.read(extended_file_name))
        file_path = decoder.file_path
        if frozen
          defroster = Defroster.new(decoder)
          defroster.files.times do |i|
            descr = defroster.descriptor(i)
            subfile_name = descr.file_name
            f = File.join(to, tape_name, file_path, subfile_name)
            dir = File.dirname(f)
            ex "mkdir -p #{shell_quote(dir)}"
            ex "gecos freezer thaw #{shell_quote(tape_name)} #{subfile_name} >#{shell_quote(f)}"
          end
        else
          f = File.join(to, tape_name, file_path)
          dir = File.dirname(f)
          ex "mkdir -p #{shell_quote(dir)}"
          ex "gecos unpack #{shell_quote(tape_name)} >#{shell_quote(f)}"
        end
      end
    end
    
    # Cross-reference the extracted files:
    # Create one directory per file, as opposed to one directory per tape
    desc "xref [ARCHIVE] [FROM] [TO]", "Create cross-reference by file name"
    option "copy", :aliases=>"-c", :type=>"boolean", :desc=>"Copy files to xref (instead of symlink)"
    def xref(archive_location=nil, from=nil, to=nil)
      @dryrun = options[:dryrun]
      directory = archive_location || Archive.location
      archive = Archive.new(directory)
      from ||= archive.extract_directory
      from = File.join(archive.location, from)
      to ||= archive.xref_directory
      to = File.join(archive.location, archive.xref_directory)
      index = {}
      reverse_index = Hash.new([])
      file_index = Hash.new([])
      
      # Create cross-reference
      ex "rm -rf #{to}"
      warn "from=#{from}"
      Dir.glob(File.join(from,'**','*')).each do |old_file|
        next if File.directory?(old_file)
        f = old_file.sub(/^#{Regexp.escape(from)}\//, '')
        if f !~ /^([^\/]+)\/(.*)$/
          warn "File #{f} does not have a tape name and file name"
        else
          # TODO Maintain an .index file
          tape = $1
          file = $2
          file_index[File.join(to, file)] << tape
          new_file = File.join(to, file, tape)
          dir = File.dirname(new_file)
          index[old_file] = new_file
          reverse_index[new_file] << old_file
          ex "mkdir -p #{shell_quote(dir)}"
          if options[:copy]
            ex "cp #{shell_quote(old_file)} #{shell_quote(new_file)}"
          else
            ex "ln -s #{shell_quote(old_file)} #{shell_quote(new_file)}"
          end
        end
      end

      # Collapse directories where there's only one file, or where they're all identical
      file_index.each do |file, tapes|
        first_tape = tapes.pop
        first_file = File.join(file, first_tape)
        contents = {first_tape => File.read(first_file)}
        tapes.each do |tape| # Look for duplicates of other files
          file_name = File.join(file, tape)
          content = File.read(file_name)
          match = nil
          contents.each do |other_tape, other_content|
            if content == other_content
              match = other_tape
              break
            end
              break
            else
              contents[]
          end
          if match
            match_file = File.join(file, match)
            abort "Reverse index [#{file_name}] has no entries" if reverse_index[file_name].size == 0
            abort "Reverse index [#{file_name}] has > 1 entry: #{reverse_index[file_name].inspect}" \ 
              if reverse_index[file_name].size > 1
            index[reverse_index[file_name].first] = match_file
            reverse_index[match_file] += reverse_index[file_name]
            reverse_index.delete(file_name)
            ex "rm #{shell_quote(file_name)}"
          end
        end
        if contents.size == 1
          temp_file = file + '.temp'
          ex "cp #{shell_quote(first_file)} #{shell_quote(temp_file)}"
          ex "rm -rf #{shell_quote(file)}"
          ex "mv #{shell_quote(temp_file)} #{shell_quote(file)}"
          reverse_index[first_file].each do |linked_file|
            index[linked_file] = file
          end
          reverse_index[file] += reverse_index[first_file]
          reverse_index.delete(first_file)
        end
      end
      
      # Create index of cross-reference
      unless @dryrun
        index_file = File.join(to, '.index')
        File.open(index_file, 'w') do |f|
          old_file_width = index.keys.map{|old_file| old_file.size}.max
          index.keys.sort.each do |old_file|
            f.puts %Q{#{"%-#{old_file_width}s" % old_file} => #{index[old_file]}}
          end
        end
      end
    end
  end
end