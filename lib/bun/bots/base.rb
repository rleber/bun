#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Class Bun::Bot::Base
#   This class is the base class for all "bots". (A bot is a Thor class, implementing a set of commands.)
#   It provides some methods allowing a bot class to be defined by simply defining each task in a separate
#   <task name>_task.rb file within the same directory.

def debug(msg)
  warn "Debug in #{caller.first}: #{msg}"
end

module Bun
  module Bot
    class Base < Thor
      # Returns the name of the source file which contains the method that invoked this method.
      # It walks up the call stack, ignoring any methods within THIS file.
      def self.calling_file
        call_stack = caller.map{|c| [c[/^(.*):\d+/,1],c[/in\s+`(.*)'/,1]]}
        called_from = call_stack.find{|c| c[0] != call_stack[0][0]}
        called_from && called_from[0]
      end
      
      # Returns the expanded file path of the directory expected to contain the subtasks.
      # If invoked from /foo/bar/scrubber.rb, this will return "/foo/bar/scrubber", for instance
      def self.task_directory
        called_from = calling_file
        ::File.expand_path(::File.join(::File.dirname(called_from), ::File.basename(called_from,'.*')))
      end
      
      # Returns an Array of all the tasks in the specified directory.
      # If no directory is specified, used the default directory (see self.task_directory)
      def self.task_names(directory=nil)
        directory ||= task_directory
        Dir.glob(::File.join(directory,'*_task.rb')).map{|t| ::File.basename(t, '.*')}
      end
      
      # Load all the tasks for the class defined in the specified directory.
      # Use the default directory if none is specified (see self.task_directory)
      def self.load_tasks(directory=nil)
        directory ||= task_directory
        task_names(directory).each {|task| load_task task, ::File.join(directory, "#{task}.rb") }
      end
    
      # Load a single task with the name given, from the file given.
      def self.load_task(task_name, file_name=nil)
        file_name ||= ::File.join(task_directory, "#{task_name}.rb")
        code = ::File.read(file_name).force_encoding('us-ascii')
        begin
          eval "class #{self.name}\n#{code}\nend",nil,file_name,0
        rescue => e
          raise "Error defining task #{task_name}: #{e}"
        end
      end

      no_tasks do
        # Thor will allow unknown options -- they are passed through with the other arguments
        # This checks for anything in the argument list starting with a "-" and throws an error if it's found
        def check_for_unknown_options(*args)
          args.each do |arg|
            arg = arg.to_s
            stop "!Unknown option: #{arg}" if arg != '-' && arg =~ /^-/
          end
        end

        # Bun examine, map, same, and find allow multiple examinations and multiple files, separated
        # by a separator marker (in the case of these commands, it's '--in'). This method splits the
        # parameter list into two arrays: one before and one after the separator.
        # The :assumed_before option allows for a fixed number of arguments to be separated into the
        # before list if no separator is found.
        def split_arguments_at_separator(separator, *args)
          options = args.last.is_a?(Hash) ? args.pop : {}
          if i = args.index(separator)
            before = args[0..i-1]
            after = args[i+1..-1]
          else
            assumed_before = options[:assumed_before] || 0
            before = args[0...assumed_before]
            after = args[assumed_before..-1]
          end
          [before, after]
        end

        def option_inspect(options)
          options.keys.sort.map do |key|
            case options[key]
            when true
              "--#{key}"
            when String
              "--#{key} #{options[key].safe}"
            else
              "--#{key} #{options.inspect}"
            end
          end.join(' ')
        end

        def puts_options(prefix="")
          s = option_inspect(options)
          puts prefix + s if s != ""
        end
      end
    end
  end
end