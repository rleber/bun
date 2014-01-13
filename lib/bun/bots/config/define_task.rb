#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

# Display definitions of configuration settings

desc "define [PAT]", "Display definition of configuration keys"
def define(pat=nil)
  check_for_unknown_options(pat)
  config = Configuration.new
  tasks = config.all_keys.sort_by {|key| key.to_s}
  pat ||= '*'
  pat = Bun.convert_glob(pat)
  selected_tasks = tasks.select {|task| task =~ pat }
  if selected_tasks.size > 0
    tasks = selected_tasks.map{|task| [task, config.class.definitions[task]]}
    tasks.unshift %W{Setting Definition}
    tasks.justify_rows.each {|task,definition| puts "#{task}  #{definition}"}
  end
end