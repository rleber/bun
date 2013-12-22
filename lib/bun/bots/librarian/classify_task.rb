#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

DEFAULT_THRESHOLD = 20
desc "classify FROM [CLEAN] [DIRTY]", "Classify files based on whether they're clean or not."
option "copy",      :aliases=>"-c", :type=>"boolean", :desc=>"Copy files to clean/dirty directories (instead of symlink)"
option 'dryrun',    :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually extract"
option 'threshold', :aliases=>'-t', :type=>'numeric',
    :desc=>"Set a threshold: how many errors before a file is 'dirty'? (default #{DEFAULT_THRESHOLD})"
def classify(from, clean=nil, dirty=nil)
  @dryrun = options[:dryrun]
  threshold = options[:threshold] || DEFAULT_THRESHOLD
  library = Library.new(from)
  directory = library.at
  from ||= library.files_directory
  log_file = File.join(from, library.log_file)
  clean = File.join(library.at, library.clean_directory)
    dirty = File.join(library.at, library.dirty_directory)
  destinations = {:clean=>clean, :dirty=>dirty}
  shell = Shell.new(:dryrun=>@dryrun)
  destinations.each do |status, destination|
    shell.rm_rf destination
    shell.mkdir_p destination
  end
  command = options[:copy] ? :cp : :ln_s

  log = read_log(log_file)

  new_logs = {:clean=>[], :dirty=>[]}
  Dir.glob(File.join(from,'**','*')).each do |old_file|
    next if File.directory?(old_file)
    f = old_file.sub(/^#{Regexp.escape(from)}\//, '')
    stop "!Missing log entry for #{old_file}" unless log[old_file]
    okay = log[old_file][:errors] < threshold
    status = okay ? :clean : :dirty
    new_file = File.join(destinations[status], f)
    dir = File.dirname(new_file)
    shell.mkdir_p dir
    warn "#{f} is #{status}"
    shell.invoke command, old_file, new_file
    new_logs[status] << alter_log(log[old_file], new_file)
  end
  new_logs.each do |status, log|
    File.open(File.join(destinations[status],library.log_file),'w') {|f| f.puts log.map{|log_entry| log_entry[:entry]}.join("\n") }
  end
end