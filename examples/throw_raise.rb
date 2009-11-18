#!/usr/bin/env ruby

require 'bullshit'

class ThrowRaise < Bullshit::RepeatCase
  compare_time            real
  warmup                  yes
  iterations              100

  N = 2_000

  autocorrelation         yes

  output_dir              'data'
  data_file               yes

  #output_filename         "#{benchmark_name}.log"

  def benchmark_throw
    N.times do
      catch(:foo) do
        throw :foo
      end
    end
  end

  def benchmark_raise
    N.times do
      begin
        raise 'foo'
      rescue
      end
    end
  end
end
