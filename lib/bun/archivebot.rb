require 'thor'
require 'mechanize'
require 'fileutils'
require 'lib/bun/archive'
require 'lib/bun/shell'
require 'lib/bun/archive_indexbot'

class Bun
  class ArchiveBot < Thor
    
    # TODO Move this to tools project; refactor
    no_tasks do
      # Fetch all files and subdirectories of a uri to a destination folder
      # The destination folder will have subfolders created, based on the structure of the uri
      # For example, fetching "http://example.com/in/a/directory/" to "data" will create a
      # copy of the contents at the uri into "data/example.com/in/a/directory"
      def _fetch(base_uri, destination, options={})
        destination.sub!(/\/$/,'') # Remove trailing slash from destination, if any
        uri_sub_path = base_uri.sub(/http:\/\/[^\/]*/,'')
        count = 0
        agent = Mechanize.new
        FileUtils::rm_rf(destination)
        process(agent, base_uri) do |page|
          relative_uri = page.uri.path.sub(/^#{Regexp.escape(uri_sub_path)}/, '')
          file_name = ::File.join(destination, relative_uri)
          dirname = ::File.dirname(file_name)
          if options[:dryrun] || !options[:quiet]
            puts "Fetch #{file_name}"
          else
            FileUtils::mkdir_p(dirname)
            ::File.open(file_name, 'w') {|f| f.write page.body}
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
    desc "fetch [URL]", "Fetch files from an online repository"
    option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
    option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Do a dry run only; show what would be fetched, but don't save it"
    option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
    long_desc <<-EOT
Fetches all the files and subdirectories of the specified online url to the data directory.

Fetched files are copied to subdirectories of the data directory. So, for instance, fetching
"http://example.com/in/a/subdirectory/" will cause files to be copied to the directory
data/example.com/in/a/subdirectory and its subdirectories, mirroring the structure online.

If no URL is provided, this command will use the location specified in the data/archive_config.yml
file or the BUN_REPOSITORY environment variable. If neither is set, the URL is mandatory.

If no "to" location is provided, this command will use the archive location specified in
data/archive_config.yml. Usually, this is ~/bun_archive
    EOT
    def fetch(url=nil)
      agent = Mechanize.new
      url ||= Archive.repository
      archive_location = options[:archive] || Archive.location
      abort "!No url provided" unless url
      abort "!No archive location provided" unless archive_location
      _fetch(url, archive_location, options)
      Archive.new(archive_location).build_and_save_index(:verbose=>!options[:quiet])
    end
    
    desc "extract [TO]", "Extract all the files in the archive"
    option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
    option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually extract"
    option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
    # TODO store metadata (e.g. description, source tape, source file type) in extended file attributes
    def extract(to=nil)
      @dryrun = options[:dryrun]
      directory = options[:archive] || Archive.location
      archive = Archive.new(directory)
      to ||= ::File.join(archive.location, archive.extract_directory)
      log_file = ::File.join(to, archive.log_file)
      ix = archive.tapes
      shell = Shell.new(:dryrun=>@dryrun)
      shell.rm_rf to
      ix.each do |tape_name|
        extended_file_name = archive.expanded_tape_path(tape_name)
        frozen = File.frozen?(extended_file_name)
        file = File::Text.open(extended_file_name)
        file_path = file.file_path
        if frozen
          frozen_file = File::Frozen.open(extended_file_name)
          frozen_file.shard_count.times do |i|
            descr = frozen_file.descriptor(i)
            subfile_name = descr.file_name
            f = ::File.join(to, tape_name, file_path, subfile_name)
            dir = ::File.dirname(f)
            shell.mkdir_p dir
            subfile_name = '\\' + subfile_name if subfile_name =~ /^\+/ # Watch out -- '+' has a special meaning to thaw
            warn "thaw #{tape_name} #{subfile_name}" unless @dryrun
            shell.thaw tape_name, subfile_name, f, :log=>log_file
          end
        else
          f = ::File.join(to, tape_name, file_path)
          dir = ::File.dirname(f)
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
    
    EXTRACT_LOG_PATTERN = /\"([^\"]*)\"(.*?)(\d+)\s+errors/
    
    no_tasks do
      def read_log(log_file_name)
        log = {}
        ::File.read(log_file_name).split("\n").each do |line|
          entry = parse_log_entry(line)
          log[entry[:file]] = entry
        end
        log
      end
      
      def parse_log_entry(log_entry)
        raise "Bad log file line: #{log_entry.inspect}" unless log_entry =~ EXTRACT_LOG_PATTERN
        {:prefix=>$`, :suffix=>$', :middle=>$2, :entry=>log_entry, :file=>$1, :errors=>$3.to_i}
      end
      
      def alter_log(log_entry, new_file)
        log_entry.merge(:file=>new_file, :entry=>"#{log_entry[:prefix]}#{new_file.inspect}#{log_entry[:middle]}#{log_entry[:errors]} errors #{log_entry[:suffix]}")
      end
    end
    
    # Cross-reference the extracted files:
    # Create one directory per file, as opposed to one directory per tape
    desc "organize [FROM] [TO]", "Create cross-reference by file name"
    option "copy", :aliases=>"-c", :type=>"boolean", :desc=>"Copy files to reorganized archive (instead of symlink)"
    option 'dryrun', :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually reorganize"
    option 'trace', :aliases=>'-t', :type=>'boolean', :desc=>"Debugging trace"
    option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
    def organize(from=nil, to=nil)
      @dryrun = options[:dryrun]
      @trace = options[:trace]
      directory = options[:archive] || Archive.location
      archive = Archive.new(directory)
      from ||= archive.extract_directory
      from = ::File.join(archive.location, from)
      to ||= archive.files_directory
      to = ::File.join(archive.location, archive.files_directory)
      index = Index.new
      
      # Build cross-reference index
      Dir.glob(::File.join(from,'**','*')).each do |old_file|
        next if ::File.directory?(old_file)
        f = old_file.sub(/^#{Regexp.escape(from)}\//, '')
        if f !~ /^([^\/]+)\/(.*)$/
          warn "File #{f} does not have a tape name and file name"
        else
          tape = $1
          file = $2
          new_file = ::File.join(to, file, tape)
          warn "#{old_file} => #{new_file}" if @trace
          index.add(:from=>old_file, :to=>new_file, :file=>file, :tape=>tape)
        end
      end
      
      # Combine files where the files have the same file name and have identical content
      index.each do |spec|
        matches = index.find(:file=>spec[:file]).reject{|e| e[:to]==spec[:to]}
        content = ::File.read(spec[:from])
        matches.each do |match|
          if ::File.read(match[:from])==content
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
      
      # Read in log information
      log = read_log(::File.join(from, archive.log_file))
      new_log = {}
      
      # Create cross-reference files
      shell = Shell.new(:dryrun=>@dryrun)
      shell.rm_rf to
      command = options[:copy] ? :cp : :ln_s
      processed = {}
      index.sort_by{|e| e[:from]}.each do |spec|
        next if processed[spec[:to]]
        processed[spec[:to]] = true   # Only need to copy or link identical files to the new location once
        dir = ::File.dirname(spec[:to])
        shell.mkdir_p dir
        warn "organize #{spec[:from]} => #{spec[:to]}" unless @dryrun
        shell.invoke command, spec[:from], spec[:to]
        abort "!No log entry for #{spec[:from]}" unless log[spec[:from]]
        new_log[spec[:to]] = alter_log(log[spec[:from]], spec[:to])
      end
      
      # Write new log
      unless @dryrun
        new_log_file = ::File.join(to, archive.log_file)
        ::File.open(new_log_file, 'w') do |f|
          new_log.keys.sort.each do |file|
            f.puts new_log[file][:entry]
          end
        end
      end

      # Create index file of cross-reference
      unless @dryrun
        index_file = ::File.join(to, '.index')
        # TODO Refactor using Array#justify_rows
        from_width = index.froms.map{|old_file| old_file.size}.max
        ::File.open(index_file, 'w') do |ixf|
          index.sort_by{|e| e[:from]}.each do |spec|
            ixf.puts %Q{#{"%-#{from_width}s" % spec[:from]} => #{spec[:to]}}
          end
        end
      end
    end
    
    DEFAULT_THRESHOLD = 20
    desc "classify [FROM] [CLEAN] [DIRTY]", "Classify files based on whether they're clean or not."
    option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
    option "copy", :aliases=>"-c", :type=>"boolean", :desc=>"Copy files to clean/dirty directories (instead of symlink)"
    option 'dryrun', :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually extract"
    option 'threshold', :aliases=>'-t', :type=>'numeric',
      :desc=>"Set a threshold: how many errors before a file is 'dirty'? (default #{DEFAULT_THRESHOLD})"
    def classify(from=nil, clean=nil, dirty=nil)
      @dryrun = options[:dryrun]
      directory = options[:archive] || Archive.location
      threshold = options[:threshold] || DEFAULT_THRESHOLD
      archive = Archive.new(directory)
      from ||= archive.files_directory
      from = ::File.join(archive.location, from)
      log_file = ::File.join(from, archive.log_file)
      clean = ::File.join(archive.location, archive.clean_directory)
        dirty = ::File.join(archive.location, archive.dirty_directory)
      destinations = {:clean=>clean, :dirty=>dirty}
      shell = Shell.new(:dryrun=>@dryrun)
      destinations.each do |status, destination|
        shell.rm_rf destination
        shell.mkdir_p destination
      end
      command = options[:copy] ? :cp : :ln_s

      log = read_log(log_file)

      new_logs = {:clean=>[], :dirty=>[]}
      Dir.glob(::File.join(from,'**','*')).each do |old_file|
        next if ::File.directory?(old_file)
        f = old_file.sub(/^#{Regexp.escape(from)}\//, '')
        abort "!Missing log entry for #{old_file}" unless log[old_file]
        okay = log[old_file][:errors] < threshold
        status = okay ? :clean : :dirty
        new_file = ::File.join(destinations[status], f)
        dir = ::File.dirname(new_file)
        shell.mkdir_p dir
        warn "#{f} is #{status}"
        shell.invoke command, old_file, new_file
        new_logs[status] << alter_log(log[old_file], new_file)
      end
      new_logs.each do |status, log|
        ::File.open(::File.join(destinations[status],archive.log_file),'w') {|f| f.puts log.map{|log_entry| log_entry[:entry]}.join("\n") }
      end
    end
    
    desc "header_sizes", "Display the length of file headers"
    option "sort", :aliases=>'-s', :type=>'string', :default=>'header', :desc=>"Sort by what field: preamble or header (size)"
    def header_sizes
      archive = Archive.new
      data = [%w{Tape Preamble Header}]
      sort_column = ['preamble', 'header'].index(options[:sort].downcase)
      abort "!Bad value for --sort option" unless sort_column
      sort_column += 1
      max_header = max_preamble = nil
      min_header = min_preamble = nil
      sum_header = sum_preamble = 0
      n = 0
      archive.tapes.each do |tape_name|
        file = archive.open(tape_name)
        preamble_size = file.content_offset
        header_size = file.header_size
        sum_preamble += preamble_size
        sum_header += header_size
        if !min_preamble || preamble_size < min_preamble
          min_preamble = preamble_size
        end
        if !max_preamble || preamble_size > max_preamble
          max_preamble = preamble_size
        end
        if !min_header || header_size < min_header
          min_header = header_size
        end
        if !max_header || header_size > max_header
          max_header = header_size
        end
        data << [tape_name, preamble_size, header_size]
        n += 1
      end
      data = data.sort_by{|row| row[sort_column].to_i }
      data = data.map{|row| row[-2] = row[-2].to_s; row[-1] = row[-1].to_s; row}
      data << ["Minimum", min_preamble.to_s, min_header.to_s]
      data << ["Average", '%0.1f' % (sum_preamble/n.to_f), '%0.1f' % (sum_header/n.to_f)]
      data << ["Maximum", max_preamble.to_s, max_header.to_s]
      puts data.justify_rows.map{|row| row.join('  ')}.join("\n")
    end
    
    # TODO Remove this
    desc "types", "List file types"
    def types
      archive = Archive.new
      archive.tapes.each do |tape_name|
        extended_file_name = archive.expanded_tape_path(tape_name)
        file = File::Header.open(extended_file_name)
        puts "#{tape_name}: #{file.fiile_type}"
      end
    end
    
    # TODO Remove me -- this was a research project
    desc "count_shards", "Count shards in frozen files three different ways"
    def count_shards
      archive = Archive.new
      table = [%w{Tape Word1 Positions Valid Flag}]
      flagged = false
      archive.tapes.each do |tape_name|
        extended_file_name = archive.expanded_tape_path(tape_name)
        file = File::Header.open(extended_file_name)
        if file.file_type == :frozen
          f = File::Frozen.open(extended_file_name)
          counts = [
            f.shard_count_based_on_word_1, 
            f.shard_count_based_on_position_of_shard_contents, 
            f.shard_count_based_on_count_of_valid_shard_descriptors
          ]
          row = [tape_name] + counts.map{|c| '%3d' % c } 
          if counts.min != counts.max
            flagged = true
            row << '*'
          else
            row << ''
          end
          table << row
        end
      end
      puts table.justify_rows.map{|row| row.join('  ')}.join("\n")
      abort "!Shard counts don't match in flagged entries" if flagged
    end

    desc "compare_offsets", "Compare file offsets vs. content of file preamble"
    def compare_offsets
      archive = Archive.new
      table = [%w{Tape Word1 Calculated Flag}]
      flagged = false
      archive.tapes.each do |tape_name|
        extended_file_name = archive.expanded_tape_path(tape_name)
        file = File::Header.open(extended_file_name)
        counts = [
          file.words.at(1).half_words.at(1).to_i, 
          file.content_offset
        ]
        row = [tape_name] + counts.map{|c| '%3d' % c } 
        if counts.min != counts.max
          flagged = true
          row << '*'
        else
          row << ''
        end
        table << row
      end
      puts table.justify_rows.map{|row| row.join('  ')}.join("\n")
      abort "!Offsets don't match in flagged entries" if flagged
    end
    
    # TODO Run this; check if there's a way to discern listing files automagically
    desc "with_tabs", "Show files containing tabs"
    def with_tabs
      archive = Archive.new
      archive.tapes.each do |tape_name|
        extended_file_name = archive.expanded_tape_path(tape_name)
        file = File::Header.open(extended_file_name)
        next if file.frozen?
        file = File::Text.open(extended_file_name)
        puts tape_name if file.content =~ /\t/
      end
    end
    
    register Bun::Archive::IndexBot, :index, "index", "Process Honeywell archive index"
  end
end