#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/archive'
require 'lib/bun/shell'

module Bun
  module Bot
    # TODO Consider combining this with bot/main.rb
    class Freezer < Base
      load_tasks
    end
  end
end