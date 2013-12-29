#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

DEFAULT_THRESHOLD = 20
desc "classify FROM TO", "Classify files based on whether they're clean or not, etc."
option 'dryrun',    :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually classify"
option "link",      :aliases=>"-l", :type=>"boolean", :desc=>"Symlink files to clean/dirty directories (instead of copy)"
option 'quiet',     :aliases=>'-d', :type=>'boolean', :desc=>"Quiet mode"
option 'test',      :aliases=>'-t', :type=>'string',  :desc=>"What test? See bun check for options"
def classify(from, clean, dirty)
  @dryrun = options[:dryrun]
  threshold = options[:threshold] || DEFAULT_THRESHOLD
  library = Library.new(from)
  directory = library.at
  clean = File.expand_path(clean)
  dirty = File.expand_path(dirty)
  destinations = {:clean=>clean, :dirty=>dirty}
  shell = Shell.new(:dryrun=>@dryrun)
  destinations.each do |status, destination|
    shell.rm_rf destination
    shell.mkdir_p destination
  end
  command = options[:copy] ? :cp : :ln_s

  Dir.glob(File.join(from,'**','*')).each do |old_file|
    next if File.directory?(old_file)
    f = old_file.sub(/^#{Regexp.escape(from)}\//, '')
    okay = File.clean?(old_file)
    status = okay ? :clean : :dirty
    new_file = File.join(destinations[status], f)
    dir = File.dirname(new_file)
    shell.mkdir_p dir
    warn "#{f} is #{status}" unless options[:quiet]
    shell.invoke command, old_file, new_file
  end
end