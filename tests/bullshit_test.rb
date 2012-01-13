#!/usr/bin/env ruby

require 'test_helper'
require 'bullshit'

module MyCases
  def setup
    @setup = true
    @befores = 0
    @afters = 0
  end

  def teardown
    @teardown = true
  end

  def setup_foo
    @setup_foo = true
  end

  def before_foo
    @befores += 1
    @before_foo = true
  end

  def benchmark_foo
    @benchmark_foo = true
    @args_foo = args rescue nil
    sleep rand(2) / 64.0
  end

  def after_foo
    @afters += 1
    @after_foo = true
  end

  def teardown_foo
    @teardown_foo = true
  end

  def setup_bar
    @setup_bar = true
  end

  def before_bar
    @before_bar = true
  end

  def benchmark_bar
    @benchmark_bar = true
  end

  def after_bar
    @after_bar = true
  end

  def teardown_bar
    @teardown_bar = true
  end

  alias iv instance_variable_get
end

class RepeatBenchmark < Bullshit::RepeatCase
  warmup      yes
  iterations  200

  output do
    dir      'data'
    filename "#{benchmark_name}.log"
  end
  data_file       yes

  autocorrelation do
    file yes
  end

  histogram do
    bins 10
  end

  include MyCases
end

class TimeBenchmark < Bullshit::TimeCase
  warmup    yes
  duration  5

  benchmark_name 'ZeitBenchmark'

  output do
    dir      'data'
    filename "#{benchmark_name}.log"
  end
  data_file       yes

  autocorrelation no

  histogram no

  include MyCases
end

class RangeBenchmark < Bullshit::RangeCase
  warmup    yes
  range     1..10
  scatter   3

  output do
    dir      'data'
    filename "#{benchmark_name}.log"
  end
  data_file       yes

  histogram no

  include MyCases
end

class BullshitTest < Test::Unit::TestCase
  include Bullshit
  Case.autorun false

  def setup
    @repeat = RepeatBenchmark.new
    @time = TimeBenchmark.new
    @range = RangeBenchmark.new
  end

  def test_version
    assert_kind_of String, ::Bullshit::VERSION
  end

  def test_repeat
    assert_equal nil, @repeat.iv(:@setup)
    assert_equal nil, @repeat.iv(:@teardown)
    assert_equal nil, @repeat.iv(:@setup_foo)
    assert_equal nil, @repeat.iv(:@before_foo)
    assert_equal nil, @repeat.iv(:@benchmark_foo)
    assert_equal nil, @repeat.iv(:@after_foo)
    assert_equal nil, @repeat.iv(:@teardown_foo)
    assert_equal nil, @repeat.iv(:@setup_bar)
    assert_equal nil, @repeat.iv(:@benchmark_bar)
    assert_equal nil, @repeat.iv(:@after_bar)
    assert_equal nil, @repeat.iv(:@teardown_bar)
    rc = Case.run_count
    @repeat.run
    assert_equal rc + 1, Case.run_count
    assert_equal true, @repeat.iv(:@setup)
    assert_equal true, @repeat.iv(:@teardown)
    assert_equal true, @repeat.iv(:@setup_foo)
    assert_equal true, @repeat.iv(:@before_foo)
    assert_equal true, @repeat.iv(:@benchmark_foo)
    assert_equal true, @repeat.iv(:@after_foo)
    assert_equal true, @repeat.iv(:@teardown_foo)
    assert_equal true, @repeat.iv(:@setup_bar)
    assert_equal true, @repeat.iv(:@benchmark_bar)
    assert_equal true, @repeat.iv(:@after_bar)
    assert_equal true, @repeat.iv(:@teardown_bar)
    assert_equal RepeatBenchmark.iterations * 2, @repeat.iv(:@befores)
    assert_equal RepeatBenchmark.iterations * 2, @repeat.iv(:@afters)
  end

  def test_time
    assert_equal nil, @time.iv(:@setup)
    assert_equal nil, @time.iv(:@teardown)
    assert_equal nil, @time.iv(:@setup_foo)
    assert_equal nil, @time.iv(:@before_foo)
    assert_equal nil, @time.iv(:@benchmark_foo)
    assert_equal nil, @time.iv(:@after_foo)
    assert_equal nil, @time.iv(:@teardown_foo)
    assert_equal nil, @time.iv(:@setup_bar)
    assert_equal nil, @time.iv(:@benchmark_bar)
    assert_equal nil, @time.iv(:@after_bar)
    assert_equal nil, @time.iv(:@teardown_bar)
    rc = Case.run_count
    @time.run
    assert_equal rc + 1, Case.run_count
    assert_equal true, @time.iv(:@setup)
    assert_equal true, @time.iv(:@teardown)
    assert_equal true, @time.iv(:@setup_foo)
    assert_equal true, @time.iv(:@before_foo)
    assert_equal true, @time.iv(:@benchmark_foo)
    assert_equal true, @time.iv(:@after_foo)
    assert_equal true, @time.iv(:@teardown_foo)
    assert_equal true, @time.iv(:@setup_bar)
    assert_equal true, @time.iv(:@benchmark_bar)
    assert_equal true, @time.iv(:@after_bar)
    assert_equal true, @time.iv(:@teardown_bar)
    assert_operator @time.iv(:@afters), '>', 2
    assert_operator @time.iv(:@befores), '>', 2
  end

  def test_range
    assert_equal nil, @range.iv(:@setup)
    assert_equal nil, @range.iv(:@teardown)
    assert_equal nil, @range.iv(:@setup_foo)
    assert_equal nil, @range.iv(:@before_foo)
    assert_equal nil, @range.iv(:@benchmark_foo)
    assert_equal nil, @range.iv(:@after_foo)
    assert_equal nil, @range.iv(:@teardown_foo)
    assert_equal nil, @range.iv(:@args_foo)
    assert_equal nil, @range.iv(:@setup_bar)
    assert_equal nil, @range.iv(:@benchmark_bar)
    assert_equal nil, @range.iv(:@after_bar)
    assert_equal nil, @range.iv(:@teardown_bar)
    assert_equal nil, @range.iv(:@args_bar)
    rc = Case.run_count
    @range.run
    assert_equal rc + 1, Case.run_count
    assert_equal true, @range.iv(:@setup)
    assert_equal true, @range.iv(:@teardown)
    assert_equal true, @range.iv(:@setup_foo)
    assert_equal true, @range.iv(:@before_foo)
    assert_equal true, @range.iv(:@benchmark_foo)
    assert_equal true, @range.iv(:@after_foo)
    assert_equal true, @range.iv(:@teardown_foo)
    assert_equal 10, @range.iv(:@args_foo)
    assert_equal true, @range.iv(:@setup_bar)
    assert_equal true, @range.iv(:@benchmark_bar)
    assert_equal true, @range.iv(:@after_bar)
    assert_equal true, @range.iv(:@teardown_bar)
    assert_equal nil, @range.iv(:@args_bar)
    runs = 2 * RangeBenchmark.range.inject(0) { |s,| s + 1 } * RangeBenchmark.scatter
    assert_equal runs, @range.iv(:@befores)
    assert_equal runs, @range.iv(:@afters)
  end
end
