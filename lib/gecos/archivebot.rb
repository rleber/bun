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
    desc "fetch [URL] [TO]", "Fetch files from an online repository"
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
      _fetch(url, archive_location)
    end
    
    SORT_VALUES = %w{tape file type}
    TYPE_VALUES = %w{all frozen normal}
    desc "ls [ARCHIVE]", "Display an index of archived files"
    option "long", :aliases=>"-l", :type=>'boolean', :desc=>"Display long format (incl. normal vs. frozen)"
    option "sort", :aliases=>"-s", :type=>'string', :default=>SORT_VALUES.first, :desc=>"Sort order for files (#{SORT_VALUES.join(', ')})"
    option "type", :aliases=>"-t", :type=>'string', :default=>TYPE_VALUES.first, :desc=>"Show only files of this type (#{TYPE_VALUES.join(', ')})"
    def ls(archive_location=nil)
      abort "Unknown --sort setting. Must be one of #{SORT_VALUES.join(', ')}" unless SORT_VALUES.include?(options[:sort])
      abort "Unknown --type setting. Must be one of #{TYPE_VALUES.join(', ')}" unless TYPE_VALUES.include?(options[:type])
      type_pattern = options[:type]=='all' ? /.*/ : /^#{Regexp.escape(options[:type])}$/i
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
      ix.each_with_index do |fi, i|
        tape_name = fi
        file_name = archive.file_path(fi)
        friz = Archive.frozen?(archive.qualified_tape_file_name(tape_name)) ? 'Frozen' : 'Normal'
        next unless friz =~ type_pattern
        file_info << {'tape'=>tape_name, 'type'=>friz, 'file'=>file_name}
      end
      sorted_info = file_info.sort_by{|fi| [fi[options[:sort]], fi['file'], fi['tape']]} # Sort it in order
      # Display it
      sorted_info.each do |entry|
        typ = options[:long] ? '%-8s'% entry['type'] : ""
        puts %Q{#{"%-#{tape_name_width}s" % entry['tape']}  #{typ}#{'%-s' % entry['file']}}
      end
    end
    
    desc "extract [ARCHIVE] [TO]", "Extract all the files in the archive"
    def extract(archive_location=nil, to=nil)
      directory = archive_location || Archive.location
      archive = Archive.new(directory)
      to ||= "output"
      ix = Archive.index
      ix.each do |entry|
        file_name = entry[0]
        extended_file_name = archive.qualified_tape_file_name(file_name)
        frozen = Defroster::frozen?(extended_file_name)
        decoder = Decoder.new(File.read(extended_file_name))
        file_path = decoder.file_path
        if frozen
          defroster = Defroster.new(decoder)
          defroster.files.times do |i|
            descr = defroster.descriptor(i)
            subfile_name = descr.file_name
            puts "gecos freeze thaw -r #{file_name} #{subfile_name} >#{to + '/' + file_name + '/' + file_path + '/' + subfile_name}"
          end
        else
          puts "gecos unpack -r #{file_name} >#{to + '/' + file_name + '/' + file_path}"
        end
      end
    end
  end
end