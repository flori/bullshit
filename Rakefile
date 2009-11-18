require 'json'
require 'flott'
include Flott
require 'open-uri'

$meta = JSON.parse(File.read('meta.json'))

task :default => [:doc, :homepage]

desc "Create the project documentation."
task :doc do
  if File.directory?('doc')
    sh 'git rm -r doc'
  end
  sh 'git commit -m "deleted documentation" doc'
  sh 'git checkout master'
  rm_rf 'doc'
  sh 'rake doc'
  sh 'git checkout gh-pages'
  sh 'git add doc'
  sh 'git commit -m "generated documentation" doc'
end

desc "Compile the homepage."
task :compile_homepage => :fetch_downloads do
  env = Environment.new
  env.update($meta)
  for tmpl in Dir['*.tmpl']
    ext = File.extname(tmpl)
    out_name = tmpl.sub(/#{ext}$/, '.html')
    warn "Compiling '#{tmpl}' -> '#{out_name}'."
    File.open(out_name, 'w') do |o|
      env.output = o
      fp = Parser.from_filename(tmpl)
      fp.evaluate(env)
    end
  end
end

desc "Fetch download files"
task :fetch_downloads do
  url = 'http://www.ping.de/~flori/'
  open(url) do |dir|
    $meta['downloads'] =
      dir.read.scan(/href="([^"]+)"/i).select do |d,|
        d =~ /\A#{$meta['project_unixname']}/
      end.map { |a| a.first }.sort_by do |v|
        v[/-((?:\d+\.){2}\d+)/, 1].split('.').map { |x| x.to_i }
      end.reverse.map do |d|
        [ url + d, d ]
      end
  end
end

desc "Check the homepage with tidy."
task :tidy_homepage do
  sh "tidy -e *index.html"
end

desc "Compile and check the homepage."
task :homepage => [ :compile_homepage, :tidy_homepage ]
