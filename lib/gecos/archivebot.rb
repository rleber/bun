require 'thor'
require 'mechanize'
require 'fileutils'
require 'gecos/archive'

class GECOS
  class ArchiveBot < Thor
    
    desc "readme", "Display helpful information for beginners"
    def readme
      STDOUT.write File.read("doc/readme.md")
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
    
    desc "index [ARCHIVE]", "Display an index of archived files"
    option "long", :aliases=>"-l", :type=>'boolean', :desc=>"Display long format (incl. normal vs. frozen)"
    def index(archive_location=nil)
      archive = Archive.new(archive_location)
      ix = archive.index
      directory = archive.location
      file_name_width = ix.map{|entry| entry.first.size}.max
      ix.each do |entry|
        file_name = entry[0]
        if options[:long]
          if Defroster::frozen?(directory + '/' + file_name)
            typ = 'Frozen '
          else
            typ = 'Normal '
          end
        else
          typ = ''
        end
        puts %Q{#{"%-#{file_name_width}s" % file_name} #{typ}#{'%-s' % entry[-1]}}
      end
    end
    
    desc "extract [ARCHIVE] [TO]", "Extract all the files in the archive"
    def extract(archive_location=nil, to=nil)
      directory = archive_location || Archive.location
      to ||= "output"
      ix = Archive.index
      ix.each do |entry|
        file_name = entry[0]
        extended_file_name = directory + '/' + file_name
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