#!/usr/bin/env ruby

puts "Creating documentation."
system "rdoc -S -d #{Dir['lib/**/*.rb'] * ' '}"
  # vim: set et sw=2 ts=2:
