#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "roff_parse", "Test Treetop-based Roff parser"
def roff_parse
  roff = Roff.new
  roff.insert_character = '^'
  loop do
    $stdout.write "> "
    line = $stdin.gets.chomp
    break if line=='' || line=='exit'
    if (res = roff.ingest(line))
      puts res.inspect
    end
  end
end
