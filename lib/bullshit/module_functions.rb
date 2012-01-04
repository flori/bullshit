module Bullshit
  module ModuleFunctions
    module_function

    # Return the angle +degree+ in radians.
    def angle(degree)
      Math.tan(Math::PI * degree / 180)
    end

    # Return the percentage number as a value in the range 0..1.
    def percent(number)
      number / 100.0
    end

    # Let a window of size +window_size+ slide over the array +array+ and yield
    # to the window array.
    def array_window(array, window_size)
      window_size < 1 and raise ArgumentError, "window_size = #{window_size} < 1"
      window_size = window_size.to_i
      window_size += 1 if window_size % 2 == 0
      radius = window_size / 2
      array.each_index do |i|
        ws = window_size
        from = i - radius
        negative_from = false
        if from < 0
          negative_from = true
          ws += from
          from = 0
        end
        a = array[from, ws]
        if (diff = window_size - a.size) > 0
          mean = a.inject(0.0) { |s, x| s + x } / a.size
          a = if negative_from
            [ mean ] * diff + a
          else
            a + [ mean ] * diff
          end
        end
        yield a
      end
      nil
    end
  end
end
