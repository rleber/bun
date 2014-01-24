#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/formatter'

desc "fields PATTERN", "List the available fields for files"
option "long", :aliases=>'-l', :type=>'boolean', :desc=>'Include descriptions'
long_desc <<-EOT
PATTERN is any valid Ruby regular expression, e.g. traits "^.*foo"
EOT
def fields(pattern='.*')
  regex = %r{#{pattern}}i
  fields = File::Descriptor::Base.all_field_definition_array.select {|row| row[0] =~ regex }
  if options[:long]
    fields = File::Descriptor::Base.all_field_definition_array.select {|row| row[0] =~ regex }
    Formatter.open('-', justify: true) do |formatter|
      formatter.titles = %w{Field Description}
      formatter.format_rows fields
    end
  else
    fields = File::Descriptor::Base.all_fields.select {|name| name =~ regex }
    puts fields
  end
end