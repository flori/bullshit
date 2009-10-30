#!/usr/bin/env ruby

require 'bullshit'
load File.join(File.dirname(__FILE__), 'fibonacci.rb')

FibonacciBenchmark.run false # to demonstrate loading, do not compare yet

Bullshit.compare do
  benchmark FibonacciBenchmark, :fib_iter, :load => yes
  benchmark FibonacciBenchmark, :fib_memo, :load => yes
end
