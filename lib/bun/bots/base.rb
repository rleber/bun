#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Class Bun::Bot::Base
#   This class is the base class for all "bots". (A bot is a Thor class, implementing a set of commands.)
#   It provides some methods allowing a bot class to be defined by simply defining each task in a separate
#   <task name>_task.rb file within the same directory.

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
        code = ::Bun.readfile(file_name, :encoding=>'us-ascii')
        begin
          eval "class #{self.name}\n#{code}\nend",nil,file_name,0
        rescue => e
          raise "Error defining task #{task_name}: #{e}"
        end
      end
    end
  end
end