#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'thor/rake_compat'

class Default < Thor
  include Thor::RakeCompat

  require 'bundler'
  Bundler::GemHelper.install_tasks
  # 
  # require 'rdoc/task'
  # if defined?(RDoc)
  #   RDoc::Task.new do |rdoc|
  #     rdoc.main     = 'README.rdoc'
  #     rdoc.rdoc_dir = 'rdoc'
  #     rdoc.title    = 'thor'
  #     rdoc.rdoc_files.include('README.rdoc', 'LICENSE', 'History.rdoc', 'Thorfile')
  #     rdoc.rdoc_files.include('lib/**/*.rb')
  #     rdoc.options << '--line-numbers' << '--inline-source'
  #   end
  # end

  desc "spec", "run the specs"
  def spec
    exec "rspec -cfs spec"
  end
end
