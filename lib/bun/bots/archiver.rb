require 'thor'
require 'mechanize'
require 'fileutils'
require 'lib/bun/archive'
require 'lib/bun/shell'
require 'lib/bun/bots/archiver/index_class'
require 'lib/bun/bots/archiver/index'

module Bun
  module Bot
    class Archiver < Base
      load_tasks
      register Bun::Bot::Archiver::Index, :index, "index", "Process Honeywell archive index"
    end
  end
end