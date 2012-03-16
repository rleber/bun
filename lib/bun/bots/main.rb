require 'thor'
# TODO Move these requires around
require 'mechanize'
require 'fileutils'
require 'lib/bun/archive'
require 'lib/bun/file'
require 'lib/bun/bots/archive'
require 'lib/bun/bots/freezer'
require 'lib/bun/bots/sandbox'
require 'lib/bun/dump'
require 'lib/bun/array'
require 'pp'

class Bun
  class Bot < BotBase
    load_tasks
    
    register Bun::FreezerBot, :freezer, "freezer", "Manage frozen Honeywell files"
    register Bun::ArchiveBot, :archive, "archive", "Manage archives of Honeywell files"
    register Bun::SandboxBot, :sandbox, 'sandbox', "Play with archive"
  end
end