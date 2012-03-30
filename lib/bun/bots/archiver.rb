#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'thor'
require 'mechanize'
require 'fileutils'
require 'lib/bun/archive'
require 'lib/bun/shell'
require 'lib/bun/bots/archiver/index_class'
require 'lib/bun/bots/archiver/index'

module Bun
  module Bot
    class Archiver < Base
      
      EXTRACT_LOG_PATTERN = /\"([^\"]*)\"(.*?)(\d+)\s+errors/

      no_tasks do
        def read_log(log_file_name)
          log = {}
          content = ::Bun.readfile(log_file_name,:encoding=>'us-ascii')
          content.split("\n").each do |line|
            entry = parse_log_entry(line)
            log[entry[:file]] = entry
          end
          log
        end

        def parse_log_entry(log_entry)
          raise "Bad log file line: #{log_entry.inspect}" unless log_entry =~ EXTRACT_LOG_PATTERN
          {:prefix=>$`, :suffix=>$', :middle=>$2, :entry=>log_entry, :file=>$1, :errors=>$3.to_i}
        end

        def alter_log(log_entry, new_file)
          log_entry.merge(:file=>new_file, :entry=>"#{log_entry[:prefix]}#{new_file.inspect}#{log_entry[:middle]}#{log_entry[:errors]} errors #{log_entry[:suffix]}")
        end
      end

      load_tasks
      register Bun::Bot::Archiver::Index, :index, "index", "Process Honeywell archive index"
    end
  end
end