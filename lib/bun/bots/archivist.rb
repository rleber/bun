#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'thor'
require 'mechanize'
require 'fileutils'
require 'lib/bun/archive'
require 'lib/bun/bots/archivist/index_class'
require 'lib/bun/bots/archivist/index'

module Bun
  module Bot
    class Archivist < Base
      load_tasks
    end
  end
end