#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "roff FILE [TO]", "Simulate the operation of ROFF"
option 'asis',    :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to decode file first"
option "debug",   :aliases=>'-D', :type=>'boolean', :desc=>"Produce debugging output"
option "dir",     :aliases=>'-d', :type=>'string',  :desc=>"Set working directory"
option "expand",  :aliases=>'-e', :type=>'boolean', :desc=>"Expand freezer archives into multiple files"
option "shard",   :aliases=>'-S', :type=>'string',  :desc=>"Select shards with this pattern (only with frozen files)"
option "summary", :aliases=>'-s', :type=>'boolean', :desc=>"Print a processing summary at the end"
def roff(from, to='-')
  check_for_unknown_options(from, to)
  shard = options[:shard]
  from, shard_2 = Bun::File.get_shard(from)
  shard = shard_2 || shard
  File::Baked.roff(from, to, options.merge(shard: shard, promote: !options[:asis]))
end