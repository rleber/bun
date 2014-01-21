#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/formatter'

desc "fields", "List the available fields for files"
option "long", :aliases=>'-l', :type=>'boolean', :desc=>'Include descriptions'
def fields
  if options[:long]
    Formatter.open('-', justify: true) do |formatter|
      formatter.titles = %w{Field Description}
      formatter.format_rows File::Descriptor::Base.all_field_definition_array
    end
  else
    puts File::Descriptor::Base.all_fields
  end
end