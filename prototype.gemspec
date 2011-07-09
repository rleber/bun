# -*- encoding: utf-8 -*-

# File structure:
# System-wide executables are in bin
# Project_wide executables are in src
# Library files are in lib
# data is for data files
# db is for db/configuration files
# doc is for documentation files
# log is for log files
# spec is for RSpec (test) files

require File.expand_path('../lib/prototype/version', __FILE__)

extra_files = ['History.rdoc', 'LICENSE', 'README.rdoc', 'Rakefile']
github_username = 'rleber'

Gem::Specification.new do |s|
  s.name = %q{prototype}
  s.version = Prototype::VERSION.dup

  if s.respond_to? :required_rubygems_version=
    s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6")
  else
    s.rubygems_version = %q{1.3.6}
  end
  s.authors = ["Richard LeBer"]
  s.date = %q{Replace Me}
  s.description = %q{Replace Me}
  s.summary = s.description
  s.email = ["richard.leber@gmail.com"]
  s.extra_rdoc_files = extra_files
  s.files = `git ls-files -- {bin,lib,spec,src,test,features}/*`.split("\n") + extra_files
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.test_files = `git ls-files -- {spec,test,features}/*`.split("\n")
  s.homepage = %q{http://github.com/#{github_username}/#{s.name}}
  s.rdoc_options = ['--charset=UTF-8', "--main", "README.rdoc"]
  s.rdoc_options << '--title' <<  s.name
  s.rdoc_options << '--line-numbers' << '--inline-source'
  s.has_rdoc = true
  s.require_paths = ["lib"]
  s.rubyforge_project = s.name


  # Add dependencies here, e.g.
  # s.add_dependency "foo", ">= 2.1.1"
  
  # Add development dependencies here
  s.add_development_dependency "bundler", "~> 1.0"
  s.add_development_dependency "rake", ">= 0.8"
  s.add_development_dependency "rdoc", "~> 2.5"
  s.add_development_dependency "rspec", "~> 2.3"
  # s.add_development_dependency "fakeweb", "~> 1.3"
  # s.add_development_dependency "simplecov", "~> 0.4"
end
