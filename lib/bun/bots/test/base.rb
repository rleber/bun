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
      
      def run_test(test)
        load_path = File.dirname(__FILE__).sub(/bun.*/,'bun')
        test_file = File.join(TEST_DIRECTORY, "#{test}_spec.rb")
        system("rspec -c -f d -I . #{test_file.inspect}")
      end

      def run(*tests)
        tests = Bun::Test.all_tests if tests == %w{all}
        tests.each do |test|
          res = run_test(test)
          stop "!Failed test" unless res
        end
      end
      
      def run_all_tests
        run('all')
      end
    end
  end
end
