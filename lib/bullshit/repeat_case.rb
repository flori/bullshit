require 'bullshit/case'

module Bullshit
  # This is a Benchmarking Case that uses a repetition limit.
  class RepeatCase < Case
    class << self
      extend DSLKit::DSLAccessor
      extend DSLKit::Constant

      constant :clock_method, :repeat

      dsl_accessor :iterations

      dsl_accessor :run_count, 0

      def message
        "Running '#{self}' for #{iterations} iterations/method"\
          " (compare_time=#{compare_time})"
      end
    end

    # Returns the evaluation for +bullshit_case+ with the results of the
    # benchmarking as a String.
    def evaluation(clock)
      clock.repeat == 0 and
        raise BullshitException, "no measurements were gauged"
      result = ''
      result << statistics_table(clock)
      result << histogram(clock)
      result << detect_outliers(clock)
      result << detect_autocorrelation(clock)
      result << "\n"
    end

    # vn heck if iterations has been set. If yes call Case#run, otherwise raise a
    # BullshitException exception.
    def run(*)
      self.class.iterations or
        raise BullshitException, 'iterations have to be set'
      super
    end
  end
end
