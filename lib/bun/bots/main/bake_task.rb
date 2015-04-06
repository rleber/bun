#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "bake FILE [TO]", "Output the ASCII content for the files"
option 'asis',   :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to decode file first"
option "expand", :aliases=>'-e', :type=>'boolean', :desc=>"Expand freezer archives into multiple files"
option "force",  :aliases=>'-f', :type=>'boolean', :desc=>"Overwrite existing files"
option "index",  :aliases=>'-i', :type=>'string',  :desc=>"Create index file"
option "quiet",  :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
option "shard",  :aliases=>'-S', :type=>'string',  :desc=>"Select shards with this pattern (only with frozen files)"
option "scrub",  :aliases=>'-s', :type=>'boolean', :desc=>"Remove control characters from output"
option "tape",   :aliases=>'-t', :type=>'string',  :desc=>"Supply tape name (use with input from STDIN)"
def bake(from, to='-')
  check_for_unknown_options(from, to)
  shard = options[:shard]
  from, shard_2 = Bun::File.get_shard(from)
  shard = shard_2 || shard
  File::Decoded.bake(from, to, options.merge(shard: shard, promote: !options[:asis], index: options[:index]))
end