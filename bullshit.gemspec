
    Gem::Specification.new do |s|
      s.name = 'bullshit'
      s.version = '0.1.0'
      s.summary = "Benchmarking is Bullshit"
      s.description = ""

      s.add_dependency('dslkit', '>= 0.2.5')

      s.files = ["tests", "tests/test_analysis.rb", "tests/test_functions.rb", "tests/test_distribution.rb", "tests/test_window.rb", "tests/test_continued_fraction.rb", "tests/test_bullshit.rb", "tests/test_newton_bisection.rb", "install.rb", "VERSION", "lib", "lib/bullshit.rb", "lib/bullshit", "lib/bullshit/version.rb", "make_doc.rb", "examples", "examples/compare.rb", "examples/josephus.rb", "examples/fibonacci.rb", "examples/sorting.rb", "examples/iteration.rb", "data", "bullshit.gemspec", "COPYING", "Rakefile"]

      s.require_path = 'lib'

      s.has_rdoc = true
      s.rdoc_options <<
        '--title' <<  'Bullshit -- Benchmarking in Ruby' <<
        '--line-numbers'
      s.test_files = ["tests/test_analysis.rb", "tests/test_functions.rb", "tests/test_distribution.rb", "tests/test_window.rb", "tests/test_continued_fraction.rb", "tests/test_bullshit.rb", "tests/test_newton_bisection.rb"]

      s.author = "Florian Frank"
      s.email = "flori@ping.de"
      s.homepage = "http://bullshit.rubyforge.org"
      s.rubyforge_project = "bullshit"
    end
  
