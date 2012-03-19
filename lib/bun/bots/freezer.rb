#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

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