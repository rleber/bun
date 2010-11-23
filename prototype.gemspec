# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{prototype}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Richard LeBer"]
  s.date = %q{Replace Me}
  s.description = %q{Replace Me}
  s.email = ["richard.leber@gmail.com"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.rdoc", "Rakefile", "lib/prototype.rb"]
  s.homepage = %q{http://github.com/#{github_username}/#{project_name}}
  s.rdoc_options = ["--main", "README.rdoc"]
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
