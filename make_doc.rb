#!/usr/bin/env ruby

puts "Creating documentation."
system "rdoc --main README --title 'Bullshit -- Benchmarking in Ruby'"\
  " -d #{Dir['lib/**/*.rb'] * ' '} README"
