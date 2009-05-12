#!/usr/bin/env ruby

require 'bullshit'

module Original
  class Person
    attr_reader :count, :prev, :next
    attr_writer :count, :prev, :next

    def initialize(count)
      @count = count
      @prev = nil
      @next = nil
    end

    def shout(shout, deadif)
      if shout < deadif
         return shout + 1
      end
      @prev.next = @next
      @next.prev = @prev
      return 1
    end
  end      

  class Chain 
    attr_reader :first
    attr_writer :first

    def initialize(size)
      @first = nil
      last = nil
      for i in (1..size)
        current = Person.new(i)
        if @first == nil
          @first = current
        end
        if last != nil
          last.next = current
          current.prev = last
        end
        last = current
      end
      @first.prev = last
      last.next = @first
    end

    def kill(nth)
      current = @first
      shout = 1
      while current.next != current
        shout = current.shout(shout,nth)
        current = current.next
      end
      @first = current
      return current
    end
  end
end

module Improved
  class Person
    attr_accessor :count, :prev, :next

    def initialize(count)
      @count = count
    end

    def shout(shout, deadif)
      if shout < deadif
         return shout + 1
      end
      @prev.next = @next
      @next.prev = @prev
      1
    end
  end      

  class Chain 
    attr_accessor :first

    def initialize(size)
      last = nil
      1.upto(size) do |i|
        current = Person.new(i)
        @first ||= current
        if last
          last.next = current
          current.prev = last
        end
        last = current
      end
      @first.prev = last
      last.next = @first
    end

    def kill(nth)
      current = @first
      shout = 1
      while current.next != current
        shout = current.shout(shout,nth)
        current = current.next
      end
      @first = current
    end
  end
end

class JosephusBenchmark < Bullshit::RepeatCase
  compare_time            real
  warmup                  aggressive
  iterations              500

  autocorrelation         yes

  N = 1001 # 41

  output_dir              'data'
  data_file               yes

  output_filename         "#{benchmark_name}.log"

  histogram do
    bins 20
  end

  def benchmark_josephus_original
    chain = Original::Chain.new(N)
    chain.kill(3)
  end

  def benchmark_josephus_improved
    chain = Improved::Chain.new(N)
    chain.kill(3)
  end
end
