#!/usr/bin/env ruby

$:.unshift File.join(ENV['HOME'], 'cvs', 'ruby', 'flott', 'lib')
require 'flott'
require 'json'
require 'fileutils'

class Homepage
  include Flott
  include FileUtils::Verbose

  def initialize(dir = Dir.pwd)
    @dir = dir
  end

  def meta
    @meta and return @meta
    Dir.chdir(@dir) do
      @meta = meta = JSON.parse(File.read('meta.json'))
    end
  end

  def publish
    Dir.chdir(@dir) do
      project = meta['project_unixname']
      sh "scp -r * rubyforge.org:/var/www/gforge-projects/#{project}/"
    end
  end

  def compile(files = Dir.glob('*.tmpl'))
    Dir.chdir(@dir) do
      env = Environment.new
      env.update(meta)
      files.each do |tmpl|
        ext = File.extname(tmpl)
        out_name = tmpl.sub(/#{ext}$/, '.html')
        STDERR.puts "Compiling '#{tmpl}' -> '#{out_name}'."
        File.open(out_name, 'w') do |o|
          env.output = o
          fp = Parser.from_filename(tmpl)
          fp.evaluate(env)
        end
      end
    end
  end
end

if $0 == __FILE__
  Homepage.new.compile
end
