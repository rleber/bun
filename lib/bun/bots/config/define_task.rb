#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

# Display definitions of configuration settings

desc "define [PAT]", "Display definition of configuration keys"
def define(pat=nil)
  config = Configuration.new
  config.read
  tasks = config.all_keys.sort
  pat ||= '*'
  pat = Bun.convert_glob(pat)
  selected_tasks = tasks.select {|task| task =~ pat }
  if selected_tasks.size > 0
    task_name_size = selected_tasks.map{|task| task.size}.max
    selected_tasks.each do |task|
      puts "#{task.ljust(task_name_size)}  #{config.definitions[task]}"
    end
  end
end