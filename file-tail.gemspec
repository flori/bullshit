# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{bullshit}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Florian Frank}]
  s.date = %q{2011-07-14}
  s.description = %q{}
  s.email = %q{flori@ping.de}
  s.executables = [%q{bs_compare}]
  s.extra_rdoc_files = [%q{README}]
  s.files = [%q{Gemfile.lock}, %q{tests}, %q{tests/test_bullshit.rb}, %q{tests/test_window.rb}, %q{examples}, %q{examples/throw_raise.rb}, %q{examples/fibonacci.rb}, %q{examples/compare.rb}, %q{examples/iteration.rb}, %q{examples/sorting.rb}, %q{examples/josephus.rb}, %q{COPYING}, %q{file-tail.gemspec}, %q{Rakefile}, %q{make_doc.rb}, %q{lib}, %q{lib/bullshit}, %q{lib/bullshit/version.rb}, %q{lib/bullshit.rb}, %q{Gemfile}, %q{CHANGES}, %q{bin}, %q{bin/bs_compare}, %q{README}, %q{VERSION}, %q{data}, %q{data/RepeatBenchmark#foo.dat}, %q{data/ZeitBenchmark#foo.dat}, %q{data/ZeitBenchmark#bar.dat}, %q{data/RepeatBenchmark#bar.dat}, %q{data/RangeBenchmark.log}, %q{data/RangeBenchmark#foo.dat}, %q{data/RepeatBenchmark.log}, %q{data/RepeatBenchmark#foo-autocorrelation.dat}, %q{data/ZeitBenchmark.log}, %q{data/RangeBenchmark#bar.dat}, %q{data/RepeatBenchmark#bar-autocorrelation.dat}, %q{install.rb}]
  s.homepage = %q{http://flori.github.com/bullshit}
  s.rdoc_options = [%q{--title}, %q{Bullshit -- Benchmarking in Ruby}, %q{--main}, %q{README}]
  s.require_paths = [%q{lib}]
  s.rubyforge_project = %q{bullshit}
  s.rubygems_version = %q{1.8.5}
  s.summary = %q{Benchmarking is Bullshit}
  s.test_files = [%q{tests/test_bullshit.rb}, %q{tests/test_window.rb}]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<dslkit>, ["~> 0.2"])
      s.add_runtime_dependency(%q<more_math>, ["~> 0.0"])
      s.add_development_dependency(%q<sdoc>, [">= 0"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
    else
      s.add_dependency(%q<dslkit>, ["~> 0.2"])
      s.add_dependency(%q<more_math>, ["~> 0.0"])
      s.add_dependency(%q<sdoc>, [">= 0"])
      s.add_dependency(%q<rcov>, [">= 0"])
    end
  else
    s.add_dependency(%q<dslkit>, ["~> 0.2"])
    s.add_dependency(%q<more_math>, ["~> 0.0"])
    s.add_dependency(%q<sdoc>, [">= 0"])
    s.add_dependency(%q<rcov>, [">= 0"])
  end
end
