require 'thor'
require 'mechanize'
require 'fileutils'
require 'gecos/archive'
require 'gecos/shell'

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
      type_pattern = case options[:type].downcase
        when 'f', 'frozen'
          /^frozen$/i
        when 'n', 'normal'
          /^normal$/i
        when '*','a','all'
          //
        else
          abort "Unknown --type setting. Should be one of #{TYPE_VALUES.join(', ')}"
        end
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
    
    # TODO Is there a lot of preamble code to these methods that could be refactored away?
    # TODO Should standardize around an --archive parameter
    desc "find PATTERN", "List tapes containing files matching a specified pattern"
    option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
    long_desc "PATTERN may be any Ruby regular expression (without the delimiting '/'s)"
    def find(pattern)
      directory = options[:archive] || Archive.location
      archive = Archive.new(directory)
      pattern = get_regexp(pattern)
      ix = archive.tapes
      ix.each do |tape_name|
        extended_file_name = archive.qualified_tape_file_name(tape_name)
        if Archive.frozen?(extended_file_name)
          decoder = Decoder.new(File.read(extended_file_name))
          defroster = Defroster.new(decoder)
          defroster.file_paths.each_with_index do |f, i|
            puts "#{tape_name}:#{defroster.file_name(i)} => #{f}" if f=~pattern
          end
        else
          decoder = Decoder.new(File.read(extended_file_name))
          f = decoder.file_path
          puts "#{tape_name} => #{f}" if f=~pattern
        end
      end
    end
    
    desc "extract [ARCHIVE] [TO]", "Extract all the files in the archive"
    option 'dryrun', :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually extract"
    def extract(archive_location=nil, to=nil)
      @dryrun = options[:dryrun]
      directory = archive_location || Archive.location
      archive = Archive.new(directory)
      to ||= File.join(archive.location, archive.extract_directory)
      log_file = File.join(to, archive.log_file)
      ix = archive.tapes
      shell = Shell.new(:dryrun=>@dryrun)
      shell.rm_rf to
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
            shell.mkdir_p dir
            subfile_name = '\\' + subfile_name if subfile_name =~ /^\+/ # Watch out -- '+' has a special meaning to thaw
            warn "thaw #{tape_name} #{subfile_name}" unless @dryrun
            shell.thaw tape_name, subfile_name, f, :log=>log_file
          end
        else
          f = File.join(to, tape_name, file_path)
          dir = File.dirname(f)
          shell.mkdir_p dir
          warn "unpack #{tape_name}" unless @dryrun
          shell.unpack tape_name, f, :log=>log_file
        end
      end
    end
    
    class Index < Array
      def add(spec)
        reject!{|e| e[:from] == spec[:from] } # Can only have one entry for any :from file
        self << spec
      end
      
      def find(spec={})
        spec = {:from=>//, :to=>//, :from=>//, :tape=>//}.merge(spec)
        spec.each {|key, pattern| spec[key] = /^#{Regexp.escape(pattern)}$/ if pattern.is_a?(String) }
        select {|e| e[:from]=~ spec[:from] && e[:to]=~spec[:to] && e[:tape]=~spec[:tape] && e[:file]=~spec[:file] }
      end
      
      def summary(field)
        map{|e| e[field]}.uniq
      end

      def files
        summary(:file)
      end
      
      def froms
        summary(:from)
      end
    end
    
    # Cross-reference the extracted files:
    # Create one directory per file, as opposed to one directory per tape
    desc "xref [ARCHIVE] [FROM] [TO]", "Create cross-reference by file name"
    option "copy", :aliases=>"-c", :type=>"boolean", :desc=>"Copy files to xref (instead of symlink)"
    option 'dryrun', :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually extract"
    option 'trace', :aliases=>'-t', :type=>'boolean', :desc=>"Debugging trace"
    def xref(archive_location=nil, from=nil, to=nil)
      @dryrun = options[:dryrun]
      @trace = options[:trace]
      archive_location = nil if archive_location == '-'
      directory = archive_location || Archive.location
      archive = Archive.new(directory)
      from ||= archive.extract_directory
      from = File.join(archive.location, from)
      to ||= archive.xref_directory
      to = File.join(archive.location, archive.xref_directory)
      index = Index.new
      
      # Build cross-reference index
      Dir.glob(File.join(from,'**','*')).each do |old_file|
        next if File.directory?(old_file)
        f = old_file.sub(/^#{Regexp.escape(from)}\//, '')
        if f !~ /^([^\/]+)\/(.*)$/
          warn "File #{f} does not have a tape name and file name"
        else
          tape = $1
          file = $2
          new_file = File.join(to, file, tape)
          warn "#{old_file} => #{new_file}" if @trace
          index.add(:from=>old_file, :to=>new_file, :file=>file, :tape=>tape)
        end
      end
      
      # Combine files where the files have the same file name and have identical content
      index.each do |spec|
        matches = index.find(:file=>spec[:file]).reject{|e| e[:to]==spec[:to]}
        content = File.read(spec[:from])
        matches.each do |match|
          if File.read(match[:from])==content
            warn "#{match[:from]} is the same as #{spec[:from]} => #{spec[:to]}" if @trace
            index.add(match.merge(:to=>spec[:to]))
          end
        end
      end
      
      # Collapse the subtree (of files for each tape) where there is only one version of a file
      index.files.each do |old_file|
        matches = index.find(:file=>old_file)
        tos = matches.map{|m| m[:to]}.uniq
        if tos.size == 1 # All the copies of this file map to the same one file
          new_to = tos.first.sub(/\/[^\/]*$/,'') # Remove the tape number at the end of the to file
          warn "Only 1 version of #{old_file} => #{new_to}" if @trace
          matches.each do |match|
            index.add(match.merge(:to=>new_to))
          end
        end
      end
      
      # Create cross-reference files
      shell = Shell.new(:dryrun=>@dryrun)
      shell.rm_rf to
      command = options[:copy] ? :cp : :ln_s
      index.sort_by{|e| e[:from]}.each do |spec|
        dir = File.dirname(spec[:to])
        shell.mkdir_p dir
        warn "#{from} => #{to}" unless @dryrun
        shell.invoke command, from, to
      end
      
      # TODO Copy log information

      # Create index file of cross-reference
      unless @dryrun
        index_file = File.join(to, '.index')
        from_width = index.froms.map{|old_file| old_file.size}.max
        File.open(index_file, 'w') do |ixf|
          index.sort_by{|e| e[:from]}.each do |spec|
            ixf.puts %Q{#{"%-#{from_width}s" % spec[:from]} => #{spec[:to]}}
          end
        end
      end
    end
    
    DEFAULT_THRESHOLD = 20
    desc "classify", "Classify files based on whether they're clean or not."
    option "copy", :aliases=>"-c", :type=>"boolean", :desc=>"Copy files to xref (instead of symlink)"
    option 'dryrun', :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually extract"
    option 'threshold', :aliases=>'-t', :type=>'numeric', :default=>DEFAULT_THRESHOLD,
      :desc=>"Set a threshold: how many errors before a file is 'dirty'?"
    def classify(archive_location=nil, from=nil, clean=nil, dirty=nil)
      @dryrun = options[:dryrun]
      archive_location = nil if archive_location == '-'
      directory = archive_location || Archive.location
      archive = Archive.new(directory)
      from ||= archive.xref_directory
      from = File.join(archive.location, from)
      clean ||= archive.xref_directory
      clean = File.join(archive.location, archive.clean_directory)
      dirty ||= archive.xref_directory
      dirty = File.join(archive.location, archive.dirty_directory)
      shell = Shell.new(:dryrun=>@dryrun)
      shell.rm_rf clean
      shell.rm_rf dirty
      command = options[:copy] ? :cp : :ln_s
      # Read in log file
      log = {}
      File.read(log_file).split("\n").each do |line|
        abort "Bad log file line: #{line.inspect}" unless line =~ /\"([^\"]*)\".*(\d+)\s+errors/
        log[$1] = $2.to_i
      end
      Dir.glob(File.join(from,'**','*')).each do |old_file|
        next if File.directory?(old_file)
        f = old_file.sub(/^#{Regexp.escape(from)}\//, '')
        okay = log[old_file] < options[:threshold]
        destination = okay ? clean : dirty
        new_file = File.join(destination, f)
        dir = File.dirname(new_file)
        shell.mkdir_p dir
        warn "#{f} is #{okay ? 'clean' : 'dirty'}"
        shell.invoke command, old_file, new_file
      end
    end
  end
end