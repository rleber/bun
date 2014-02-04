#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "roff_parse", "Test Treetop-based Roff parser"
def roff_parse
  roff = Roff.new
  quote_control_characters=['"', "'", nil]
  loop do
    qc = quote_control_characters.first
    roff.quote_character = qc
    quote_control_characters.rotate!
    $stdout.puts "Insert character is #{qc.inspect}"
    $stdout.write "> "
    line = $stdin.gets.chomp
    break if line=='' || line=='exit'
    if (res = roff.expand(line))
      puts res.inspect
      puts res.expand.inspect
    end
  end
end
