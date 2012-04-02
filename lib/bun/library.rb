#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

require 'lib/bun/collection'
require 'lib/bun/file'
require 'date'

module Bun
  class Library < Collection
    
    def files(&blk)
      contents(&blk)
    end
    
    def contents(&blk)
      glob('**/*', &blk)
    end
    
    def open(name, options={}, &blk)
      File::Library.open(expand_path(name), options.merge(:library=>self,  :location=>name), &blk)
    end
    
    # Options:
    # - :compact
    # - :dryrun
    def compact(options={})
    end
  end
end