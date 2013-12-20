#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    class Huffman < Bun::File::Archived
    end
  end
end