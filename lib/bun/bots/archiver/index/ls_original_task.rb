desc "ls_original", "List the original index file for the archive"
option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
def ls_original
  archive = Archive.new(options[:archive])
  # TODO Use Array.justify_rows
  archive.original_index.each do |spec|
    puts "#{spec[:tape]}  #{spec[:date].strftime('%Y/%d/%m')}  #{spec[:file]}"
  end
end
