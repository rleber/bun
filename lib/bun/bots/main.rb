#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'thor'
# TODO Move these requires around
require 'mechanize'
require 'fileutils'
require 'lib/bun/archive'
require 'lib/bun/library'
require 'lib/bun/file'
require 'lib/bun/bots/archivist'
require 'lib/bun/bots/config'
require 'lib/bun/bots/place'
require 'lib/bun/bots/librarian'
require 'lib/bun/bots/freezer'
require 'lib/bun/bots/sandbox'
require 'lib/bun/bots/test'
require 'lib/bun/dump'
require 'lib/array'
require 'pp'

module Bun
  module Bot
    class Main < Base
      load_tasks
      
      register Bun::Bot::Archivist, :archive, "archive", "Manage archives of Honeywell files"
      register Bun::Bot::Config,    :config,  "config",  "Manage configuration"
      register Bun::Bot::Freezer,   :freezer, "freezer", "Manage frozen Honeywell files"
      register Bun::Bot::Librarian, :library, "library", "Manage libraries of decoded Honeywell files"
      register Bun::Bot::Place,     :places,  "places",  "Manage defined places (files/URLs)"
      register Bun::Bot::Sandbox,   :sandbox, 'sandbox', "Play with archive"
      register Bun::Bot::Test,      :test,    'test',    "Run tests"
    end
  end
end