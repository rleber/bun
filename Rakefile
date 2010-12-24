require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/prototype'

Hoe.plugin :newgem
Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'rleber-mysql' do
  self.developer 'Richard LeBer', 'richard.leber@gmail.com'
  self.rubyforge_name       = self.name # TODO this is default value
  # self.extra_deps         = [['activesupport','>= 2.0.2']]

end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]

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

