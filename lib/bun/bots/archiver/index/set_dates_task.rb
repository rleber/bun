desc "set_dates", "Set file modification dates for archived files, based on catalog"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually set dates"
def set_dates
  archive = Archive.new(options[:archive])
  shell = Bun::Shell.new(options)
  archive.each do |tape|
    descr = archive.descriptor(tape)
    timestamp = descr[:updated]
    if timestamp
      puts "About to set timestamp: #{tape} #{timestamp.strftime('%Y/%m/%d %H:%M:%S')}" unless options[:quiet]
      shell.set_timestamp(archive.expanded_tape_path(tape), timestamp)
    else
      puts "No updated time available for #{tape}" unless options[:quiet]
    end
  end
end
