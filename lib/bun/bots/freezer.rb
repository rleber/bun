require 'lib/bun/archive'
require 'lib/bun/shell'

class Bun

  # TODO Consider combining this with bot.rb
  class FreezerBot < BotBase
    load_tasks
  end
end
