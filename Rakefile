# vim: set et sw=2 ts=2:

begin
  require 'rake/gempackagetask'
rescue LoadError
end
require 'rbconfig'
include Config

PKG_NAME = 'bullshit'
PKG_VERSION = File.read('VERSION').chomp
PKG_FILES = FileList['**/*'].exclude(/^(doc|CVS|pkg|coverage)/)

desc "Run unit tests"
task :test do
  sh %{RUBYOPT="-Ilib $RUBYOPT" testrb tests/*.rb}
end

desc "Testing library with coverage"
task :coverage do
  sh 'rcov -x tests -Ilib tests/*.rb'
end

desc "Installing library"
task :install  do
  ruby 'install.rb'
end

desc "Creating documentation"
task :doc do
  ruby 'make_doc.rb'
end

desc "Removing generated files"
task :clean => :clean_data do
  rm_rf 'doc'
  rm_rf 'coverage'
end

desc "Removing contents of data directory"
task :clean_data do
  rm_rf Dir['data/*']
end

if defined? Gem
  spec = Gem::Specification.new do |s|
    s.name = 'bullshit'
    s.version = PKG_VERSION
    s.summary = "Benchmarking is Bullshit"
    s.description = ""

    s.add_dependency('dslkit', '>= 0.2.5')

    s.files = PKG_FILES

    s.require_path = 'lib'

    s.has_rdoc = true
    s.rdoc_options <<
      '--title' <<  'Bullshit -- Benchmarking in Ruby' <<
      '--line-numbers'
    s.test_files.concat Dir['tests/*.rb']

    s.author = "Florian Frank"
    s.email = "flori@ping.de"
    s.homepage = "http://bullshit.rubyforge.org"
    s.rubyforge_project = "bullshit"
  end

  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
    pkg.package_files += PKG_FILES
  end
end

desc m = "Writing version information for #{PKG_VERSION}"
task :version do
  puts m
  File.open(File.join('lib', 'bullshit', 'version.rb'), 'w') do |v|
    v.puts <<EOT
module Bullshit
  # Bullshit version
  VERSION         = '#{PKG_VERSION}'
  VERSION_ARRAY   = VERSION.split(/\\./).map { |x| x.to_i } # :nodoc:
  VERSION_MAJOR   = VERSION_ARRAY[0] # :nodoc:
  VERSION_MINOR   = VERSION_ARRAY[1] # :nodoc:
  VERSION_BUILD   = VERSION_ARRAY[2] # :nodoc:
end
EOT
  end
end

task :default => [ :version, :test ]

task :release => [ :version, :clean, :package ]
  # vim: set et sw=2 ts=2:
