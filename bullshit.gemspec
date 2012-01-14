# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "bullshit"
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Florian Frank"]
  s.date = "2012-01-14"
  s.description = "Library to benchmark ruby code and analyse the results"
  s.email = "flori@ping.de"
  s.executables = ["bs_compare"]
  s.extra_rdoc_files = ["README.rdoc", "lib/bullshit/comparison.rb", "lib/bullshit/block_configuration.rb", "lib/bullshit/covering_extension.rb", "lib/bullshit/version.rb", "lib/bullshit/truncate_data_extension.rb", "lib/bullshit/output_extension.rb", "lib/bullshit/autocorrelation_extension.rb", "lib/bullshit/histogram_extension.rb", "lib/bullshit/case_method.rb", "lib/bullshit/common_constants.rb", "lib/bullshit/range_case.rb", "lib/bullshit/detect_outliers_extension.rb", "lib/bullshit/module_functions.rb", "lib/bullshit/repeat_case.rb", "lib/bullshit/case_extension.rb", "lib/bullshit/evaluation_module.rb", "lib/bullshit/time_case.rb", "lib/bullshit/clock.rb", "lib/bullshit/case.rb", "lib/bullshit.rb"]
  s.files = [".gitignore", ".travis.yml", "CHANGES", "COPYING", "Gemfile", "README.rdoc", "Rakefile", "VERSION", "bin/bs_compare", "bullshit.gemspec", "data/.keep", "examples/compare.rb", "examples/fibonacci.rb", "examples/iteration.rb", "examples/josephus.rb", "examples/sorting.rb", "examples/throw_raise.rb", "lib/bullshit.rb", "lib/bullshit/autocorrelation_extension.rb", "lib/bullshit/block_configuration.rb", "lib/bullshit/case.rb", "lib/bullshit/case_extension.rb", "lib/bullshit/case_method.rb", "lib/bullshit/clock.rb", "lib/bullshit/common_constants.rb", "lib/bullshit/comparison.rb", "lib/bullshit/covering_extension.rb", "lib/bullshit/detect_outliers_extension.rb", "lib/bullshit/evaluation_module.rb", "lib/bullshit/histogram_extension.rb", "lib/bullshit/module_functions.rb", "lib/bullshit/output_extension.rb", "lib/bullshit/range_case.rb", "lib/bullshit/repeat_case.rb", "lib/bullshit/time_case.rb", "lib/bullshit/truncate_data_extension.rb", "lib/bullshit/version.rb", "tests/bullshit_test.rb", "tests/test_helper.rb", "tests/window_test.rb"]
  s.homepage = "http://flori.github.com/bullshit"
  s.rdoc_options = ["--title", "Bullshit -- Benchmarking in Ruby", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.13"
  s.summary = "Benchmarking is Bullshit"
  s.test_files = ["tests/bullshit_test.rb", "tests/window_test.rb", "tests/test_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<gem_hadar>, ["~> 0.1.4"])
      s.add_runtime_dependency(%q<tins>, ["~> 0.3"])
      s.add_runtime_dependency(%q<dslkit>, ["~> 0.2.10"])
      s.add_runtime_dependency(%q<more_math>, ["~> 0.0.2"])
    else
      s.add_dependency(%q<gem_hadar>, ["~> 0.1.4"])
      s.add_dependency(%q<tins>, ["~> 0.3"])
      s.add_dependency(%q<dslkit>, ["~> 0.2.10"])
      s.add_dependency(%q<more_math>, ["~> 0.0.2"])
    end
  else
    s.add_dependency(%q<gem_hadar>, ["~> 0.1.4"])
    s.add_dependency(%q<tins>, ["~> 0.3"])
    s.add_dependency(%q<dslkit>, ["~> 0.2.10"])
    s.add_dependency(%q<more_math>, ["~> 0.0.2"])
  end
end
