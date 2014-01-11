#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

# List settings in current configuration

desc "ls [PAT]", "List place definitions"
def ls(pat=nil)
  check_for_unknown_options(pat)
  config = Configuration.new
  places = config.places
  place_names = places.keys.sort
  pat ||= '*'
  pat = Bun.convert_glob(pat)
  selected_place_names = place_names.select {|task| task =~ pat }
  if selected_place_names.size > 0
    table = selected_place_names.map do |place|
      [place, places[place]]
    end
    table.unshift ["Place","Definition"]
    puts table.justify_rows.map{|row| row.join('  ')}.join("\n")
  end
end