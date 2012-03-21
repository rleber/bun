#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

EXTRACT_LOG_PATTERN = /\"([^\"]*)\"(.*?)(\d+)\s+errors/

no_tasks do
  def read_log(log_file_name)
    log = {}
    File.read(log_file_name).split("\n").each do |line|
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
option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
option "copy",    :aliases=>"-c", :type=>"boolean", :desc=>"Copy files to reorganized archive (instead of symlink)"
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually reorganize"
option 'trace',   :aliases=>'-t', :type=>'boolean', :desc=>"Debugging trace"
def organize(from=nil, to=nil)
  @dryrun = options[:dryrun]
  @trace = options[:trace]
  directory = options[:archive] || Archive.location
  archive = Archive.new(:location=>directory)
  from ||= archive.extract_directory
  from = File.join(archive.location, from)
  to ||= archive.files_directory
  to = File.join(archive.location, archive.files_directory)
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
  
  # Read in log information
  log = read_log(File.join(from, archive.log_file))
  new_log = {}
  
  # Create cross-reference files
  shell = Shell.new(:dryrun=>@dryrun)
  shell.rm_rf to
  command = options[:copy] ? :cp : :ln_s
  processed = {}
  index.sort_by{|e| e[:from]}.each do |spec|
    next if processed[spec[:to]]
    processed[spec[:to]] = true   # Only need to copy or link identical files to the new location once
    dir = File.dirname(spec[:to])
    shell.mkdir_p dir
    warn "organize #{spec[:from]} => #{spec[:to]}" unless @dryrun
    shell.invoke command, spec[:from], spec[:to]
    stop "!No log entry for #{spec[:from]}" unless log[spec[:from]]
    new_log[spec[:to]] = alter_log(log[spec[:from]], spec[:to])
  end
  
  # Write new log
  unless @dryrun
    new_log_file = File.join(to, archive.log_file)
    File.open(new_log_file, 'w') do |f|
      new_log.keys.sort.each do |file|
        f.puts new_log[file][:entry]
      end
    end
  end

  # Create index file of cross-reference
  unless @dryrun
    index_file = File.join(to, '.index')
    # TODO Refactor using Array#justify_rows
    from_width = index.froms.map{|old_file| old_file.size}.max
    File.open(index_file, 'w') do |ixf|
      index.sort_by{|e| e[:from]}.each do |spec|
        ixf.puts %Q{#{"%-#{from_width}s" % spec[:from]} => #{spec[:to]}}
      end
    end
  end
end