--- !ruby/object:Gem::Specification 
name: bullshit
version: !ruby/object:Gem::Version 
  version: 0.1.0
platform: ruby
authors: 
- Florian Frank
autorequire: 
bindir: bin
cert_chain: []

date: 2009-05-13 00:00:00 +02:00
default_executable: 
dependencies: 
- !ruby/object:Gem::Dependency 
  name: dslkit
  type: :runtime
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        version: 0.2.5
    version: 
description: ""
email: flori@ping.de
executables: []

extensions: []

extra_rdoc_files: []

files: 
- tests
- tests/test_analysis.rb
- tests/test_functions.rb
- tests/test_distribution.rb
- tests/test_window.rb
- tests/test_continued_fraction.rb
- tests/test_bullshit.rb
- tests/test_newton_bisection.rb
- install.rb
- VERSION
- lib
- lib/bullshit.rb
- lib/bullshit
- lib/bullshit/version.rb
- make_doc.rb
- examples
- examples/compare.rb
- examples/josephus.rb
- examples/fibonacci.rb
- examples/sorting.rb
- examples/iteration.rb
- data
- bullshit.gemspec
- COPYING
- Rakefile
has_rdoc: true
homepage: http://bullshit.rubyforge.org
post_install_message: 
rdoc_options: 
- --title
- Bullshit -- Benchmarking in Ruby
- --line-numbers
require_paths: 
- lib
required_ruby_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
  version: 
required_rubygems_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
  version: 
requirements: []

rubyforge_project: bullshit
rubygems_version: 1.3.1
signing_key: 
specification_version: 2
summary: Benchmarking is Bullshit
test_files: 
- tests/test_analysis.rb
- tests/test_functions.rb
- tests/test_distribution.rb
- tests/test_window.rb
- tests/test_continued_fraction.rb
- tests/test_bullshit.rb
- tests/test_newton_bisection.rb
