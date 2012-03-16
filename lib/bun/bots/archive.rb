require 'thor'
require 'mechanize'
require 'fileutils'
require 'lib/bun/archive'
require 'lib/bun/shell'
require 'lib/bun/bots/archive/index_class'
require 'lib/bun/bots/archive/index'

class Bun
  class ArchiveBot < BotBase
    load_tasks
    register Bun::Archive::IndexBot, :index, "index", "Process Honeywell archive index"
  end
end