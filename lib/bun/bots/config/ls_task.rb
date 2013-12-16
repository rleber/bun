#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

# List settings in current configuration

desc "ls [PAT]", "Display configuration information"
option "expand",   :aliases=>"-e", :type=>'boolean', :desc=>"Expand file settings"
def ls(pat=nil)
  config = Configuration.new
  config.read
  tasks = config.all_keys.sort
  pat ||= '*'
  pat = Bun.convert_glob(pat)
  selected_tasks = tasks.select {|task| task =~ pat }
  if selected_tasks.size > 0
    task_name_size = selected_tasks.map{|task| task.size}.max
    selected_tasks.each do |task|
      value = (options[:expand] && task =~ /_path$/) ? config.expanded_setting(task) : config.setting[task]
      puts "#{task.ljust(task_name_size)}  #{value}"
    end
  end
end