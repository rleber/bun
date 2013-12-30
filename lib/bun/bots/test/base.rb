#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

TEST_DIRECTORY = 'spec'

module Bun
  class Test
    class << self
      def all_tests
        Dir.glob(TEST_DIRECTORY + '/*_spec.rb') \
          .map{|f| f.sub(/^#{TEST_DIRECTORY}\//,'').sub(/_spec.rb$/,'')}
      end
      
      def run(*tests)
        tests = Bun::Test.all_tests if tests == %w{all}
        load_path = File.dirname(__FILE__).sub(/bun.*/,'bun')
        test_files = tests.map{|test| File.join(TEST_DIRECTORY, "#{test}_spec.rb") }
        test_spec = test_files.map{|test| test.inspect}.join(' ')
        system("rspec -c -f d -I . #{test_spec}")
      end
      
      def run_all_tests
        run('all')
      end
    end
  end
end
