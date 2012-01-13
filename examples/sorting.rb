#!/usr/bin/env ruby

require 'bullshit'

class SortingBenchmark < Bullshit::RangeCase
  compare_time            real
  warmup                  yes
  range                   1..200
  scatter                 3

  data_file               yes
  output do
    dir 'data'
  end

  def prepare_random_array
    @ary = Array.new(args) { rand(args * 10) }
  end

  def prepare_sorted_array
    @ary = Array.new(args) { rand(args * 10) }
    @ary.sort!
  end

  def check_result
    @result == @ary.sort or raise "sorting failure"
  end

  # Ruby internal sort (an optimized quicksort implementation)

  # random array
  alias before_ruby_sort prepare_random_array

  def benchmark_ruby_sort
    @result = @ary.sort
  end

  alias after_ruby_sort check_result

  # sorted array
  alias before_ruby_sort_sorted prepare_sorted_array

  alias benchmark_ruby_sort_sorted benchmark_ruby_sort

  alias after_ruby_sort_sorted check_result

  # Quicksort in Ruby

  def quicksort(a)
    return [] if a.empty?
    left, right = a[1..-1].partition { |y| y <= a.first }
    quicksort(left) + [ a.first ] + quicksort(right)
  end

  # random array
  alias before_quicksort prepare_random_array

  def benchmark_quicksort
    @result = quicksort @ary
  end

  alias after_quicksort check_result

  # sorted array
  alias before_quicksort_sorted prepare_sorted_array

  alias benchmark_quicksort_sorted benchmark_quicksort

  alias after_quicksort_sorted check_result

  # Quicksort in Ruby with median pivot

  def find_median_index(orig_a)
    a = orig_a.dup
    k = a.size / 2
    l = 0
    m = a.size - 1
    while l < m
      x = a[k]
      i = l
      j = m
      begin
        i += 1 while a[i] < x
        j -= 1 while x < a[j]
        if i <= j
          a[i], a[j] = a[j], a[i]
          i += 1
          j -= 1
        end
      end while i <= j
      l = i if j < k
      m = j if k < i
    end
    orig_a.index(a[k])
  end

  def median_quicksort(a)
    return [] if a.empty?
    i = find_median_index a
    a[0], a[i] = a[i], a[0]
    left, right = a[1..-1].partition { |y| y <= a.first }
    median_quicksort(left) + [ a.first ] + median_quicksort(right)
  end

  # random array
  alias before_median_quicksort prepare_random_array

  def benchmark_median_quicksort
    @result = median_quicksort @ary
  end

  alias after_median_quicksort check_result

  # sorted array
  alias before_median_quicksort_sorted prepare_sorted_array

  alias benchmark_median_quicksort_sorted benchmark_median_quicksort

  alias after_median_quicksort_sorted check_result

  # Insertionsort-Quicksort-Hybrid in Ruby

  def quicksort_hybrid(a)
    if a.size < 7
      insertionsort(a)
    else
      i = find_median_index a
      a[0], a[i] = a[i], a[0]
      left, right = a[1..-1].partition { |y| y <= a.first }
      quicksort_hybrid(left) + [ a.first ] + quicksort_hybrid(right)
    end
  end

  # random array
  alias before_quicksort_hybrid prepare_random_array

  def benchmark_quicksort_hybrid
    @result = quicksort_hybrid @ary
  end

  alias after_quicksort_hybrid check_result

  # sorted array
  alias before_quicksort_hybrid_sorted prepare_sorted_array

  alias benchmark_quicksort_hybrid_sorted benchmark_quicksort_hybrid

  alias after_quicksort_hybrid_sorted check_result

  # Selectionsort in Ruby

  def selectionsort(a)
    a = a.dup
    for start in 0...(a.size - 1)
      min = start
      for i in (start + 1)...a.size
        a[i] < a[min] and min = i
      end
      a[start], a[min] = a[min], a[start]
    end
    a
  end

  # random array
  alias before_selectionsort prepare_random_array

  def benchmark_selectionsort
    @result = selectionsort @ary
  end

  alias after_selectionsort check_result

  # sorted array
  alias before_selectionsort_sorted prepare_sorted_array

  alias benchmark_selectionsort_sorted benchmark_selectionsort

  alias after_selectionsort_sorted check_result

  # Insertionsort in Ruby

  def insertionsort(a)
    a = a.dup
    for i in 1...a.size
      j, x = i - 1, a[i]
      while j >= 0 and a[j] > x
        a[j + 1] = a[j]
        j -= 1
      end
      a[j + 1] = x
    end
    a
  end

  # random array
  alias before_insertionsort prepare_random_array

  def benchmark_insertionsort
    @result = insertionsort @ary
  end

  alias after_insertionsort check_result

  # sorted array
  alias before_insertionsort_sorted prepare_sorted_array

  alias benchmark_insertionsort_sorted benchmark_insertionsort

  alias after_insertionsort_sorted check_result

  # Shellsort in Ruby

  def shellsort(a)
    a = a.dup
    s = a.size / 2
    while s > 0
      for i in 0...a.size
        j, t = i, a[i]
        while j >= s and a[j - s] > t
          a[j] = a[j - s]
          j -= s
        end
        a[j] = t
      end
      s = s == 1 ? 0 : s / 2
    end
    a
  end

  # random array
  alias before_shellsort prepare_random_array

  def benchmark_shellsort
    @result = shellsort @ary
  end

  alias after_shellsort check_result

  # sorted array
  alias before_shellsort_sorted prepare_sorted_array

  alias benchmark_shellsort_sorted benchmark_shellsort

  alias after_shellsort_sorted check_result

  # Bubblesort in Ruby

  def bubblesort(a)
    a = a.dup
    for j in 0...a.size
       for i in 1...(a.size - j)
           a[i], a[i - 1] = a[i - 1], a[i] if a[i] < a[i - 1]
       end
     end
    a
  end

  # random array
  alias before_bubblesort prepare_random_array

  def benchmark_bubblesort
    @result = bubblesort @ary
  end

  alias after_bubblesort check_result

  # sorted array
  alias before_bubblesort_sorted prepare_sorted_array

  alias benchmark_bubblesort_sorted benchmark_bubblesort

  alias after_bubblesort_sorted check_result

  # Mergesort in Ruby

  def merge(a, b)
    case
    when a.empty?          then b
    when b.empty?          then a
    when a.first < b.first then a[0, 1].concat merge(a[1..-1], b)
    else                        b[0, 1].concat merge(a, b[1..-1])
    end
  end

  def mergesort(a)
    if a.size <= 1
      a
    else
      mid = a.size / 2
      merge( mergesort(a[0, mid]), mergesort(a[mid..-1]) )
    end
  end

  # random array
  alias before_mergesort prepare_random_array

  def benchmark_mergesort
    @result = mergesort @ary
  end

  alias after_mergesort check_result

  # sorted array
  alias before_mergesort_sorted prepare_sorted_array

  alias benchmark_mergesort_sorted benchmark_mergesort

  alias after_mergesort_sorted check_result

  # Heapsort in Ruby
  def sift_down(a, start, ende)
    root = start
    while root * 2 + 1 <= ende
      child = root * 2 + 1
      if child + 1 <= ende and a[child] < a[child + 1]
        child += 1
      end
      if a[root] < a[child]
        a[root], a[child] = a[child], a[root]
        root = child
      else
        return
      end
    end
  end

  def heapify(a)
    count = a.size

    start = (count - 2) / 2
    while start >= 0
      sift_down(a, start, count - 1)
      start -= 1
    end
  end

  def heapsort(a)
    a = a.dup
    heapify(a)

    ende = a.size - 1
    while ende > 0
      a[ende], a[0] = a[0], a[ende]
      ende -= 1
      sift_down(a, 0, ende)
    end
    a
  end

  # random array
  alias before_heapsort prepare_random_array

  def benchmark_heapsort
    @result = heapsort @ary
  end

  alias after_heapsort check_result

  # sorted array
  alias before_heapsort_sorted prepare_sorted_array

  alias benchmark_heapsort_sorted benchmark_heapsort

  alias after_heapsort_sorted check_result
end
