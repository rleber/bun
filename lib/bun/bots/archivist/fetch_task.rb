#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

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
      file_name = File.join(destination, relative_uri)
      dirname = File.dirname(file_name)
      if options[:dryrun] || !options[:quiet]
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
desc "fetch URL ARCHIVE", "Fetch files from an online repository"
option 'at',      :aliases=>'-a', :type=>'string',  :desc=>'Archive path'
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Do a dry run only; show what would be fetched, but don't save it"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
long_desc <<-EOT
Fetches all the files and subdirectories of the specified online url to the data directory.

Fetched files are copied to subdirectories of the data directory. So, for instance, fetching
"http://example.com/in/a/subdirectory/" will cause files to be copied to the directory
data/example.com/in/a/subdirectory and its subdirectories, mirroring the structure online.

# TODO: not true
If no URL is provided, this command will use the location specified in the bun config file.
The archive is fetched to the specified location
EOT
def fetch(url, at)
  agent = Mechanize.new
  archive = Archive.new(at)
  _fetch(url, archive.location, options)
end