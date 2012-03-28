#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "extract [TO]", "Extract all the files in the archive"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually extract"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
def extract(to=nil)
  @dryrun = options[:dryrun]
  archive = Archive.new(:location=>options[:archive])
  directory = archive.location
  to ||= File.join(archive.location, archive.extract_directory)
  log_file = File.join(to, archive.log_file)
  ix = archive.locations
  shell = Shell.new(:dryrun=>@dryrun)
  shell.rm_rf to
  ix.each do |location|
    file = archive.open(location)
    file_path = file.path
    case file.file_type
    when :frozen
      file.shard_count.times do |i|
        descr = file.shard_descriptor(i)
        shard_name = descr.name
        f = File.join(to, location, file_path, shard_name)
        dir = File.dirname(f)
        shell.mkdir_p dir
        shard_name = '\\' + shard_name if shard_name =~ /^\+/ # Watch out -- '+' has a special meaning to thaw
        warn "thaw #{location} #{shard_name}" unless @dryrun
        shell.thaw location, shard_name, f, :log=>log_file
      end
    when :text
      f = File.join(to, location, file_path)
      dir = File.dirname(f)
      shell.mkdir_p dir
      warn "unpack #{location}" unless @dryrun
      shell.unpack location, f, :log=>log_file
    else
      warn "skipping #{location}: unknown type (#{file.file_type})"
    end
  end
end