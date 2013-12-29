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
#{
  String.check_tests.to_a.map do |key,spec| 
    [key.to_s, spec[:description]]
  end.justify_rows.map{|row| row.join(': ')}.join("\x5")
}
EOT
def check(file)
  res = Bun::File.check(file, options[:test])
  puts res[:description] unless options[:quiet]
  code = res[:code] || 0
  exit(code)
rescue String::InvalidCheck => e
  warn "!Invalid test: #{options[:test]}" unless options[:quiet]
  exit(99)
end
