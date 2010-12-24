# -*- encoding: utf-8 -*-

require File.expand_path('../lib/prototype/version', __FILE__)

extra_files = ['History.rdoc', 'LICENSE', 'README.rdoc', 'Manifest.txt']

Gem::Specification.new do |s|
  s.name = %q{prototype}
  s.version = Prototype::VERSION.dup

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.authors = ["Richard LeBer"]
  s.date = %q{Replace Me}
  s.description = %q{Replace Me}
  s.summary = s.description
  s.email = ["richard.leber@gmail.com"]
  s.extra_rdoc_files = extra_files
  s.files = `git ls-files -- {bin,lib,spec,test}/*`.split("\n") + extra_files
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.test_files = `git ls-files -- {spec,test}/*`.split("\n")
  s.homepage = %q{http://github.com/#{github_username}/#{project_name}}
  s.rdoc_options = ['--charset=UTF-8', "--main", "README.rdoc"]
  s.rdoc_options << '--title' <<  s.name
  s.has_rdoc = true
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{prototype}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Replace Me}
  s.test_files = ["test/test_helper.rb", "test/test_prototype.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rubyforge>, [">= 2.0.4"])
      s.add_development_dependency(%q<gemcutter>, [">= 0.5.0"])
      s.add_development_dependency(%q<hoe>, [">= 2.5.0"])
    else
      s.add_dependency(%q<rubyforge>, [">= 2.0.4"])
      s.add_dependency(%q<gemcutter>, [">= 0.5.0"])
      s.add_dependency(%q<hoe>, [">= 2.5.0"])
    end
  else
    s.add_dependency(%q<rubyforge>, [">= 2.0.4"])
    s.add_dependency(%q<gemcutter>, [">= 0.5.0"])
    s.add_dependency(%q<hoe>, [">= 2.5.0"])
  end
  # Add dependencies here, e.g.
  # s.add_dependencey("foo", [">= 2.1.1"])
end
