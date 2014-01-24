#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/formatter'

desc "traits PATTERN", "List the available traits for files"
option "long",    :aliases=>'-l', :type=>'boolean', :desc=>'Include descriptions'
option "options", :aliases=>'-o', :type=>'boolean', :desc=>'Show options usage information for traits'
long_desc <<-EOT
PATTERN is any valid Ruby regular expression, e.g. traits "^.*foo"
EOT
def traits(pattern='.*')
  regex = %r{#{pattern}}i
  traits = String::Trait.traits.select {|name| name =~ regex }
  long = options[:long] || options[:options]
  rows = traits.map do |trait|
    long ? String::Trait.trait_definitions.find {|name, defn| name == trait } : [trait]
  end
  Formatter.open("-", justify: true) do |usage_formatter|
    if options[:options]
      usage_formatter.titles = %w{Trait/Options Description}
    elsif long
      usage_formatter.titles = %w{Trait Description}
    end
    rows.each do |row|
      usage_formatter << row
      next if !options[:options]
      trait_class = String::Trait.trait_class(row[0])
      trait_class.option_definitions.each do |usage_defn|
        usage_formatter << ["  "+usage_defn[:name], "  "+usage_defn[:desc]]
      end
    end
  end
end