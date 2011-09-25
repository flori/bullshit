# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "bullshit"
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Florian Frank"]
  s.date = "2011-09-25"
  s.description = "Library to benchmark ruby code and analyse the results"
  s.email = "flori@ping.de"
  s.executables = ["bs_compare"]
  s.extra_rdoc_files = ["README.rdoc", "lib/bullshit/version.rb", "lib/bullshit.rb"]
  s.files = [".gitignore", ".travis.yml", "CHANGES", "COPYING", "Gemfile", "README.rdoc", "Rakefile", "VERSION", "bin/bs_compare", "bullshit.gemspec", "data/.keep", "examples/compare.rb", "examples/fibonacci.rb", "examples/iteration.rb", "examples/josephus.rb", "examples/sorting.rb", "examples/throw_raise.rb", "lib/bullshit.rb", "lib/bullshit/version.rb", "tests/test_bullshit.rb", "tests/test_window.rb"]
  s.homepage = "http://flori.github.com/bullshit"
  s.rdoc_options = ["--title", "Bullshit -- Benchmarking in Ruby", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.10"
  s.summary = "Benchmarking is Bullshit"
  s.test_files = ["tests/test_bullshit.rb", "tests/test_window.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<gem_hadar>, ["~> 0.1.0"])
      s.add_runtime_dependency(%q<tins>, ["~> 0.3"])
      s.add_runtime_dependency(%q<dslkit>, ["~> 0.2"])
      s.add_runtime_dependency(%q<more_math>, ["~> 0.0.2"])
    else
      s.add_dependency(%q<gem_hadar>, ["~> 0.1.0"])
      s.add_dependency(%q<tins>, ["~> 0.3"])
      s.add_dependency(%q<dslkit>, ["~> 0.2"])
      s.add_dependency(%q<more_math>, ["~> 0.0.2"])
    end
  else
    s.add_dependency(%q<gem_hadar>, ["~> 0.1.0"])
    s.add_dependency(%q<tins>, ["~> 0.3"])
    s.add_dependency(%q<dslkit>, ["~> 0.2"])
    s.add_dependency(%q<more_math>, ["~> 0.0.2"])
  end
end
