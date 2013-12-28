#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO Am I necessary?
module Bun
  class File < ::File
    class RawHeader < Bun::File::Raw
    end
  end
end