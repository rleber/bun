#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO -- As is, this is kind of useless. It just checks the raw ASCII of a file
desc "check FILE", "Test a file for cleanness -- i.e. does it contain non-printable characters?"
def check(file)
  content = ::Bun.readfile(file, :encoding=>'ascii-8bit')
  if File.clean?(content)
    puts "File is clean"
  else
    stop "File is dirty"
  end
end
