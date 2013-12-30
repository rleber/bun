#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

# List settings in current configuration

desc "ls [PAT]", "Display configuration information"
def ls(pat=nil)
  config = Configuration.new
  tasks = config.all_keys.sort
  pat ||= '*'
  pat = Bun.convert_glob(pat)
  selected_tasks = tasks.select {|task| task =~ pat && task != :places }
  if selected_tasks.size > 0
    table = selected_tasks.map do |task|
      [task, config.setting[task].inspect]
    end
    table.unshift ["Config","Setting"]
    puts table.justify_rows.map{|row| row.join('  ')}.join("\n")
  end
end