#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/archive'
require 'lib/bun/shell'

module Bun
  module Bot
    class Test < Base
      load_tasks
    end
  end
end