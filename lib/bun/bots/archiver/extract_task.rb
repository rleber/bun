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
  ix = archive.tapes
  shell = Shell.new(:dryrun=>@dryrun)
  shell.rm_rf to
  ix.each do |tape_name|
    extended_file_name = archive.expanded_tape_path(tape_name)
    frozen = File.frozen?(extended_file_name)
    file = File::Text.open(extended_file_name)
    file_path = file.file_path
    if frozen
      frozen_file = File::Frozen.open(extended_file_name)
      frozen_file.shard_count.times do |i|
        descr = frozen_file.descriptor(i)
        subfile_name = descr.file_name
        f = File.join(to, tape_name, file_path, subfile_name)
        dir = File.dirname(f)
        shell.mkdir_p dir
        subfile_name = '\\' + subfile_name if subfile_name =~ /^\+/ # Watch out -- '+' has a special meaning to thaw
        warn "thaw #{tape_name} #{subfile_name}" unless @dryrun
        shell.thaw tape_name, subfile_name, f, :log=>log_file
      end
    else
      f = File.join(to, tape_name, file_path)
      dir = File.dirname(f)
      shell.mkdir_p dir
      warn "unpack #{tape_name}" unless @dryrun
      shell.unpack tape_name, f, :log=>log_file
    end
  end
end