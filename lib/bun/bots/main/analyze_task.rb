#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO add --mark option
desc "analyze FILE", "Analyze and generate statistics on a file"
option 'mark',  :aliases=>'-m', :type=>'boolean', :desc=>"Mark the test in the file"
option 'test',  :aliases=>'-t', :type=>'string',  
                :desc=>"What analysis? See bun help analyze for options",
                :default=>'characters'
option 'quiet', :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
long_desc <<-EOT
Calculates statistics on a file.

Available analyses include:\x5

controls:  Analyze control characters\x5
chars:     Count all characters\x5
classe:    Count text, punctuation, and non_printable characters\x5
printable: Count printable vs. non-printable characters

EOT
def analyze(file)
  analyzer = Bun::File.analyze(file, options[:test])
  test_result = analyzer.to_s
  puts test_result unless options[:quiet]
  Bun::File::Unpacked.mark(file, {options[:test]=>test_result}) if options[:mark]
rescue String::Analysis::Invalid => e
  warn "!Invalid analysis: #{options[:test]}" unless options[:quiet]
  exit(99)
end
