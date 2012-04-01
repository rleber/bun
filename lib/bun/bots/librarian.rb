#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'thor'
require 'lib/bun/library'

module Bun
  module Bot
    class Librarian < Base
      load_tasks
    end
  end
end