#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'shellwords'

TEST_DIRECTORY = 'spec'

module Bun
  class Test
    BACKTRACE_FILE = "output/test_actual/_backtrace.txt"
    ACTUAL_OUTPUT_DIRECTORY = "output/test_actual"
    EXPECTED_OUTPUT_DIRECTORY = "output/test_expected"
    LAST_OUTPUT_FILE = "#{ENV['HOME']}/.bun_test_actual_output_file"
    PROJECT_DIRECTORY = Bun.project_path(__FILE__)
    
    class << self
      def all_tests
        Dir.glob(TEST_DIRECTORY + '/*_spec.rb') \
          .map{|f| f.sub(/^#{TEST_DIRECTORY}\//,'').sub(/_spec.rb$/,'')}
      end
      
      def run(*tests)
        options = tests.last.is_a?(Hash) ? tests.pop : {}
        tests = Bun::Test.all_tests if tests == %w{all}
        load_path = File.dirname(__FILE__).sub(/bun.*/,'bun')
        test_files = tests.map{|test| File.join(TEST_DIRECTORY, "#{test}_spec.rb") }
        params = options[:params] || {}
        e_param = options[:examples] ? ["-e", options[:examples]] : nil
        test_files.each do |test_file|
          expanded_test_file = File.join(PROJECT_DIRECTORY, test_file)
          stop "!File #{expanded_test_file} does not exist" unless File.exists?(expanded_test_file)
        end
        cmd_line = ['rspec','-c', '-f', 'd', '-I', '.', e_param, test_files].flatten.compact.shelljoin
        $stderr.puts cmd_line
        system(params, cmd_line)
      end
      
      def run_all_tests
        run('all')
      end
      
      def backtrace(options={})
        commands = ::File.read(BACKTRACE_FILE).chomp.split("\n") rescue []
        all = 0...(commands.size)
        n = options[:range] || all
        n = begin
          n.is_a?(String) ? eval(n) : n
        rescue
          nil
        end
        case n
        when Numeric
          n = 0..([n.to_i, commands.size-1].min)
        when Range
          # Do nothing
        else
          raise ArgumentError, "Unexpected trace range: #{options[:range].inspect}"
        end
        commands = commands[n]
        unless options[:preserve]
          commands = commands.map do |c|
            words = c.shellsplit
            words = words.map do |word|
              word.match(/^((?:\d?[|<>](?:&\d)?)?)(.*)/)
              $1 + ($2 == '' ? '' : $2.shellescape)
            end
            words.join(' ')
          end
        end
        commands
      end
      
      def diff(actual, expected=nil)
        expected ||= actual.sub(/^#{ACTUAL_OUTPUT_DIRECTORY}/,'')
        actual = File.join(ACTUAL_OUTPUT_DIRECTORY, actual) unless actual =~ /^#{ACTUAL_OUTPUT_DIRECTORY}/
        expected = File.join(EXPECTED_OUTPUT_DIRECTORY, expected) unless expected =~ /^#{EXPECTED_OUTPUT_DIRECTORY}/
        system(['diff', actual, expected].shelljoin)
      end

      def save_actual_output(file)
        content = Bun.readfile(file)
        ::File.open(LAST_OUTPUT_FILE, 'w') {|f| f.write file}
      end

      def last_actual_output_file
        ::File.read(LAST_OUTPUT_FILE)
      end
    end
  end
end
