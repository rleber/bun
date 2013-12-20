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
    table = [["Config","Setting"]] + selected_tasks.map do |task|
      [task, (options[:expand] && task =~ /_path$/) ? config.expanded_setting(task) : config.setting[task]]
    end
    puts table.justify_rows.map{|row| row.join('  ')}.join("\n")
  end
end