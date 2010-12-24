require 'rubygems'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'rdoc/task'
if defined?(RDoc)
  RDoc::Task.new do |rdoc|
    rdoc.main     = 'README.rdoc'
    rdoc.rdoc_dir = 'rdoc'
    rdoc.title    = 'rleber-table'
    rdoc.rdoc_files.include('README.rdoc', 'LICENSE', 'History.rdoc', 'Thorfile')
    rdoc.rdoc_files.include('lib/**/*.rb')
    rdoc.options << '--line-numbers' << '--inline-source'
  end
end

