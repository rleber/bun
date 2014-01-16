#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "tar ARCHIVE TAR_FILE", "Compress the specified archive into a tar file"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode; really only makes sense with --copy"
def tar(archive, tar_file)
  check_for_unknown_options(archive, tar_file)
  Archive.tar(archive, tar_file, options)
end