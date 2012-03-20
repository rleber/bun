#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

if $0 == 'irb'
  class Abort < RuntimeError; end
end

# Use stop instead of abort, in case we're testing in irb
def stop(msg)
  if $0 == 'irb'
    warn msg
    raise Abort, msg
  else
    abort msg
  end
end