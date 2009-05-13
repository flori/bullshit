require 'homepage'

ch = Homepage.new

task :default => [:doc, :homepage]

desc "Create the project documentation."
task :doc do
  rm_rf 'doc'
  sh 'git checkout master'
  sh 'rake doc'
  sh 'git checkout gh-pages'
  sh 'git add doc'
  sh 'git commit -m "generated documentation" doc'
end

desc "Compile the homepage."
task :compile_homepage do
  ch.compile
end

desc "Check the homepage with tidy."
task :tidy_homepage do
  sh "tidy -e index.html"
end

task :homepage => [ :compile_homepage, :tidy_homepage ]

desc "Publish the homepage."
task :publish => [ :doc, :homepage ] do
  ch.publish
end
  # vim: set et sw=2 ts=2:
