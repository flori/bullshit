#!/usr/bin/env ruby

require 'bullshit'
require File.join(File.dirname(__FILE__), 'fibonacci')

FibonacciBenchmark.run # to demonstrate loading

Bullshit.compare do
  benchmark FibonacciBenchmark, :fib_iter, :load => yes
  benchmark FibonacciBenchmark, :fib_memo, :load => yes
end
