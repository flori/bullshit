#!/usr/bin/env ruby

puts "Creating documentation."
system "rdoc -S -d #{Dir['lib/**/*.rb'] * ' '}"
