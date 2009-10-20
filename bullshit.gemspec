# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name = 'bullshit'
  s.version = '0.1.1'
  s.summary = "Benchmarking is Bullshit"
  s.description = ""

  s.add_dependency('dslkit', '>= 0.2.5')

  s.files = ["CHANGES", "COPYING", "Rakefile", "VERSION", "bin", "bin/bs_compare", "bullshit.gemspec", "data", "examples", "examples/compare.rb", "examples/fibonacci.rb", "examples/iteration.rb", "examples/josephus.rb", "examples/sorting.rb", "install.rb", "lib", "lib/bullshit", "lib/bullshit.rb", "lib/bullshit/version.rb", "make_doc.rb", "tests", "tests/test_analysis.rb", "tests/test_bullshit.rb", "tests/test_continued_fraction.rb", "tests/test_distribution.rb", "tests/test_functions.rb", "tests/test_newton_bisection.rb", "tests/test_window.rb"]

  s.require_path = 'lib'
  s.executables = 'bs_compare'

  s.has_rdoc = true
  s.rdoc_options <<
    '--title' <<  'Bullshit -- Benchmarking in Ruby' <<
    '--line-numbers'
  s.test_files = ["tests/test_analysis.rb", "tests/test_bullshit.rb", "tests/test_continued_fraction.rb", "tests/test_distribution.rb", "tests/test_functions.rb", "tests/test_newton_bisection.rb", "tests/test_window.rb"]

  s.author = "Florian Frank"
  s.email = "flori@ping.de"
  s.homepage = "http://bullshit.rubyforge.org"
  s.rubyforge_project = "bullshit"
end
