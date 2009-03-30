#!/usr/bin/env ruby

require 'rbconfig'
require 'fileutils'
include FileUtils::Verbose

include Config

file = 'lib/bullshit.rb'
libdir = CONFIG["sitelibdir"]
install(file, libdir, :mode => 0755)
mkdir_p subdir = File.join(libdir, 'bullshit')
for f in Dir['lib/bullshit/*.rb']
  install(f, subdir)
end
    # vim: set et sw=4 ts=4:
