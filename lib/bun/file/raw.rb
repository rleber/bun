#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO Am I necessary?
module Bun
  class File < ::File
    class Raw < Bun::File::Archived
    end
  end
end