require 'bullshit/case'

module Bullshit
  # A range case is a benchmark case, where each iteration depends on a
  # different argument, which might cause a non-constant running time. The
  # evaluation of the case doesn't check for constancy and steady-state
  # properties.
  class RangeCase < Case
    class << self
      constant :clock_method, :scale_range

      dsl_accessor :range

      dsl_accessor :scatter, 1

      dsl_accessor :run_count, 0

      def message
        "Running '#{self}' for range #{range.inspect}"\
          " (compare_time=#{compare_time})"
      end

      attr_accessor :args
    end

    def args
      self.class.args
    end
    private :args

    # Returns the evaluation for +bullshit_case+ with the results of the
    # benchmarking as a String.
    def evaluation(clock)
      clock.repeat == 0 and
        raise BullshitException, "no measurements were gauged"
      result = ''
      result << statistics_table(clock)
      result << "\n"
    end

    # Check if iterations has been set. If yes call Case#run, otherwise raise a
    # BullshitException exception.
    def run(*)
      self.class.range or
        raise BullshitException,
          'range has to be set to an enumerable of arguments'
      super
    end
  end
end
