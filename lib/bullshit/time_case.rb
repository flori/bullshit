require 'bullshit/case'

module Bullshit
  # This is a Benchmarking Case that uses a time limit.
  class TimeCase < Case
    class << self
      constant :clock_method, :time

      dsl_accessor :duration

      dsl_accessor :run_count, 0

      def message
        "Running '#{self}' for a duration of #{duration} secs/method"\
          " (compare_time=#{compare_time}):"
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

    # Check if duration has been set. If yes call Case#run, otherwise raise a
    # BullshitException exception.
    def run(*)
      self.class.duration or
        raise BullshitException, 'duration has to be set'
      super
    end
  end
end
