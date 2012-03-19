#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

desc "check FILE", "Test a file for cleanness -- i.e. does it contain non-printable characters?"
def check(file)
  if File.clean?(File.read(file))
    puts "File is clean"
  else
    stop "File is dirty"
  end
end