#!/usr/bin/env ruby

require 'test_helper'
require 'bullshit'

class WindowTest < Test::Unit::TestCase
  include Bullshit::ModuleFunctions

  def array_windows(array, window_size)
    result = []
    array_window(array, window_size) do |a|
      result << a
    end
    result
  end

  def setup
    @e = []
    @a = (1..5).to_a
    @b = (1..2).to_a
    @c = (1..6).to_a
  end

  def test_array_windows
    assert_equal [], array_windows(@e, 3)
    assert_equal [ [ 1.5, 1, 2 ], [ 1, 2, 3 ], [ 2, 3, 4 ], [ 3, 4, 5 ], [ 4, 5, 4.5 ] ],
      array_windows(@a, 3)
    assert_equal [ [ 1.5, 1, 2 ], [ 1, 2, 1.5 ] ], array_windows(@b, 3)
    assert_equal [ [ 1.5, 1, 2 ], [ 1, 2, 3 ], [ 2, 3, 4 ], [ 3, 4, 5 ], [ 4, 5, 4.5 ] ],
      array_windows(@a, 3)
    assert_equal [ [ 2.0, 2.0, 1, 2, 3 ], [ 2.5, 1, 2, 3, 4 ], [ 1, 2, 3, 4, 5 ],
      [ 2, 3, 4, 5, 6 ], [ 3, 4, 5, 6, 4.5 ], [ 4, 5, 6, 5.0, 5.0 ] ], array_windows(@c, 5)
  end
end
