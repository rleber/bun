#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO add --mark option
desc "check FILE", "Test a file for cleanness, etc."
option 'test',  :aliases=>'-t', :type=>'string',  :desc=>"What test? See bun help check for options",
                :default=>'clean'
option 'quiet', :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
long_desc <<-EOT
Checks the file to see whether it passes certain tests.

Available tests include:\x5

clean: Text does not contain unprintable characters
readability: Proportion of readable textual characters in text

EOT
def check(file)
  checker = Bun::File.check(file, options[:test])
  puts checker.to_s
  exit checker.code
rescue String::Check::Invalid => e
  warn "!Invalid check: #{options[:test]}" unless options[:quiet]
  exit(99)
end
