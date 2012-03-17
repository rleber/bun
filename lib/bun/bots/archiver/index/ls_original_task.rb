desc "ls_catalog", "List the catalog file for the archive"
option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
def ls_catalog
  archive = Archive.new(options[:archive])
  # TODO Use Array.justify_rows
  archive.catalog.each do |spec|
    puts "#{spec[:tape]}  #{spec[:date].strftime('%Y/%d/%m')}  #{spec[:file]}"
  end
end
