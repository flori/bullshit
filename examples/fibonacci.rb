#!/usr/bin/env ruby

require 'bullshit'

class FibonacciBenchmark < Bullshit::RepeatCase
  warmup              yes

  iterations          500

  truncate_data do
    alpha_level 0.05
    window_size 10
    slope_angle 0.003
  end

  output do
    dir 'data'
  end
  data_file  yes
  histogram  yes

  autocorrelation do
    alpha_level 0.05
    max_lags    50
    file        yes
  end

  detect_outliers yes

  MIN_N =   10_000
  RANGE_N = 100

  def rand_n
    MIN_N + rand(RANGE_N + 1)
  end

  def fib_iter(n)
    a, b = 0, 1
    while (n -= 1) >= 0
        a, b = a + b, a
    end
    a
  end

  def fib_memo(n)
    @fib_memo ||= Hash.new do |f, i|
      f[i] = fib_iter(i)
    end
    @fib_memo[n]
  end

  def before_fib_iter
    @n = rand_n
  end

  def benchmark_fib_iter
    @result = fib_iter(@n)
  end

  def after_fib_iter
    @result == fib_iter(@n) or raise "wrong result"
  end

  def before_fib_memo
    @n = rand_n
  end

  def benchmark_fib_memo
    @result = fib_memo(@n)
  end

  def after_fib_memo
    @result == fib_iter(@n) or raise "wrong result"
  end

  def teardown_fib_memo
    @fib_memo = nil
  end
end
