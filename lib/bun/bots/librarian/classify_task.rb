#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

DEFAULT_THRESHOLD = 20
desc "classify FROM TO", "Classify files based on whether they're clean or not, etc."
option 'dryrun',    :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually classify"
option "link",      :aliases=>"-l", :type=>"boolean", :desc=>"Symlink files to clean/dirty directories (instead of copy)"
option 'quiet',     :aliases=>'-d', :type=>'boolean', :desc=>"Quiet mode"
option 'test',      :aliases=>'-t', :type=>'string',  :desc=>"What test? See bun check for options",
                    :default=>'clean'
def classify(from, to)
  @dryrun = options[:dryrun]
  threshold = options[:threshold] || DEFAULT_THRESHOLD
  library = Library.new(from)
  shell = Shell.new(:dryrun=>@dryrun)
  shell.rm_rf(to) if File.exists?(to)
  command = options[:copy] ? :cp : :ln_s

  Dir.glob(File.join(from,'**','*')).each do |old_file|
    next if File.directory?(old_file)
    f = old_file.sub(/^#{Regexp.escape(from)}\//, '')
    status = Bun::File.check(old_file, options[:test])[:description]
    new_file = File.join(to, status.to_s, f)
    shell.mkdir_p File.dirname(new_file)
    warn "#{f} is #{status}" unless options[:quiet]
    shell.invoke command, old_file, new_file
  end
end