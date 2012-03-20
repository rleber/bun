#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'thor'
# TODO Move these requires around
require 'mechanize'
require 'fileutils'
require 'lib/bun/archive'
require 'lib/bun/file'
require 'lib/bun/bots/archiver'
require 'lib/bun/bots/freezer'
require 'lib/bun/bots/sandbox'
require 'lib/bun/bots/catalog'
require 'lib/bun/dump'
require 'lib/array'
require 'pp'

module Bun
  module Bot
    class Main < Base
      load_tasks
    
      register Bun::Bot::Freezer,  :freezer, "freezer", "Manage frozen Honeywell files"
      register Bun::Bot::Archiver, :archive, "archive", "Manage archives of Honeywell files"
      register Bun::Bot::Catalog,  :catalog, "catalog", "Process the catalog of archival tapes"
      register Bun::Bot::Sandbox,  :sandbox, 'sandbox', "Play with archive"
    end
  end
end