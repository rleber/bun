#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

EXTRACT_DATE_FORMAT = "%Y%m%d_%H%M%S"
EXTRACT_SUFFIX = '.txt'

no_tasks do
  def extract_path(path, date)
    return path unless date
    date_to_s = date.strftime(EXTRACT_DATE_FORMAT)
    date_to_s = $1 if date_to_s =~ /^(.*)_000000$/
    path + '_' + date_to_s
  end
  
  def extract_filename(path, date)
    extract_path(path, date) + EXTRACT_SUFFIX
  end
end

desc "extract TO", "Extract all the files in the archive"
option 'at',      :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually extract"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
def extract(to)
  @dryrun = options[:dryrun]
  @quiet = options[:quiet]
  archive = Archive.new(:at=>options[:at])
  to_path = archive.expand_path(to, :from_wd=>true) # @/foo form is allowed
  ix = archive.locations
  FileUtils.rm_rf to_path unless @dryrun
  ix.each do |location|
    file = archive.open(location)
    file_path = file.path
    case file.file_type
    when :frozen
      file.shard_count.times do |i|
        descr = file.shard_descriptor(i)
        shard_name = descr.name
        warn "thaw #{location}[#{shard_name}]" if @dryrun || !@quiet
        unless @dryrun
          f = File.join(to_path, extract_path(file_path, file.updated), shard_name, extract_filename(location, descr.updated))
          dir = File.dirname(f)
          FileUtils.mkdir_p dir
          file.extract shard_name, f
        end
      end
    when :text
      warn "unpack #{location}" if @dryrun || !@quiet
      unless @dryrun
        f = File.join(to_path, file_path, extract_filename(location, file.updated))
        dir = File.dirname(f)
        FileUtils.mkdir_p dir
        file.extract f
      end
    else
      warn "skipping #{location}: unknown type (#{file.file_type})" if @dryrun || !@quiet
    end
  end
end