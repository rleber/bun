#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO add --mark option
desc "analyze FILE", "Analyze and generate statistics on a file"
option 'test',  :aliases=>'-t', :type=>'string',  
                :desc=>"What analysis? See bun help analyze for options",
                :default=>'characters'
option 'quiet', :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
long_desc <<-EOT
Calculates statistics on a file.

Available analyses include:\x5
#{
  String.analyses.to_a.map do |key,spec| 
    [key.to_s, spec[:description]]
  end.justify_rows.map{|row| row.join(': ')}.join("\x5")
}
EOT
def analyze(file)
  analyzer = Bun::File.analyze(file, options[:test])
  puts analyzer.to_s
rescue String::Analysis::Invalid => e
  warn "!Invalid analysis: #{options[:test]}" unless options[:quiet]
  exit(99)
end
