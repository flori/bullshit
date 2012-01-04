#!/usr/bin/env ruby

require 'bullshit'

module MyCases
  def setup
    @n = 1_000
    @setup_general = true
  end

  def teardown
    raise 'setup_general not set' unless @setup_general
  end

  def setup_for
    @test_setup = true
  end

  def benchmark_for
    a = []
    for i in 1 .. @n
      a << i ** 2
    end
  end

  def teardown_for
    raise "test_setup not set" unless @test_setup
  end

  def benchmark_times
    a = []
    i = 1
    @n.times do
      a << i ** 2
      i += 1
    end
  end

  def benchmark_loop
    a = []
    i = 1
    loop do
      i < @n or break
      a << i ** 2
      i += 1
    end
  end

  def benchmark_while
    a = []
    i = 1
    while i < @n
      a << i ** 2
      i += 1
    end
  end

  def benchmark_while_fast
    i = 1
    while i < @n
      a = i ** 2
      i += 1
    end
  end

  def benchmark_inject
    (1..@n).inject([]) { |a, i| a << i ** 2 }
  end

  def benchmark_inject2
    (1..@n).inject([]) { |a, i| a << i ** 2 }
  end
end

class IterationTimeBenchmark < Bullshit::TimeCase
  compare_time        total
  warmup              yes
  duration            1
  batch_size          5

  covering do
    alpha_level         0.01
  end

  autocorrelation do
    file yes
  end

  output_dir          'data'
  data_file           yes

  histogram           yes

  include MyCases
end

class IterationRepeatBenchmark < Bullshit::RepeatCase
  warmup              yes
  iterations          1000

  covering do
    alpha_level         0.01
  end

  autocorrelation     yes

  data_file           yes
  output_dir          'data'

  histogram do
    bins 20
    file yes
  end

  include MyCases
end
