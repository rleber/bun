#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

if $0 == 'irb'
  class Abort < RuntimeError; end
end

# Use stop instead of abort, in case we're testing in irb
def stop(msg=nil)
  if $0 == 'irb'
    warn msg if msg
    raise Abort, msg
  else
    abort msg if msg
    exit(1)
  end
end