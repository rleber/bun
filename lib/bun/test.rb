#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'shellwords'

TEST_DIRECTORY = 'spec'

module Bun
  class Test
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
        cmd_line = ['rspec','-c', '-f', 'd', '-I', '.', e_param, test_files].flatten.compact.shelljoin
        $stderr.puts cmd_line
        system(params, cmd_line)
      end
      
      def run_all_tests
        run('all')
      end
    end
  end
end
