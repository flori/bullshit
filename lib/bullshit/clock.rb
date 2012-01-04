module Bullshit
  # A Clock instance is used to take measurements while benchmarking.
  class Clock
    include MoreMath

    TIMES = [ :real, :total, :user, :system ]

    ALL_COLUMNS = [ :scatter ] + TIMES + [ :repeat ]

    TIMES_MAX = TIMES.map { |t| t.to_s.size }.max

    # Returns a Clock instance for CaseMethod instance +bc_method+.
    def initialize(bc_method)
      @bc_method = bc_method
      @times = Hash.new { |h, k| h[k] = [] }
      @repeat = 0
      @scatter = 0
    end

    # Use a Clock instance to measure the time necessary to do
    # bc_method.case.iterations repetitions of +bc_method+.
    def self.repeat(bc_method)
      clock = new(bc_method)
      bs = clock.case.batch_size.abs
      bs = 1 if !bs or bs < 0
      clock.case.iterations.times do
        bc_method.before_run
        $DEBUG and warn "Calling #{bc_method.name}."
        clock.inc_scatter
        clock.measure do
          bs.times { yield }
        end
        bc_method.after_run
      end
      clock
    end

    # Use a Clock instance to measure how many repetitions of +bc_method+ can
    # be done in bc_method.case.duration seconds (a float value). If the
    # bc_method.case.batch_size is >1 duration is multiplied by batch_size
    # because the measured times are averaged by batch_size.
    def self.time(bc_method)
      clock = new(bc_method)
      duration = clock.case.duration.abs
      if bs = clock.case.batch_size and bs > 1
        duration *= bs
      end
      until_at = Time.now + duration
      bs = clock.case.batch_size.abs
      bs = 1 if !bs or bs < 0
      begin
        bc_method.before_run
        $DEBUG and warn "Calling #{bc_method.name}."
        clock.inc_scatter
        clock.measure do
          bs.times { yield }
        end
        bc_method.after_run
      end until clock.time > until_at
      clock
    end

    # Iterate over the +range+ of the RangeCase instance of this +bc_method+
    # and take measurements (including scattering).
    def self.scale_range(bc_method)
      clock = new(bc_method)
      my_case = clock.case
      bs = my_case.batch_size.abs
      bs = 1 if !bs or bs < 0
      for a in my_case.range
        begin
          my_case.args = (a.dup rescue a).freeze
          clock.inc_scatter
          my_case.scatter.times do
            bc_method.before_run
            $DEBUG and warn "Calling #{bc_method.name}."
            clock.measure do
              bs.times { yield }
            end
            bc_method.after_run
          end
        ensure
          my_case.args = nil
        end
      end
      clock
    end

    # The benchmark case class this clock belongs to (via bc_method).
    def case
      @bc_method.case.class
    end

    # Returns the benchmark method for this Clock instance.
    attr_reader :bc_method

    # Number of repetitions this clock has measured.
    attr_accessor :repeat

    # Last time object used for real time measurement.
    attr_reader :time

    # Return all the slopes of linear regressions computed during data
    # truncation phase.
    attr_reader :slopes

    # Add the array +times+ to this clock's time measurements. +times+ consists
    # of the time measurements in float values in order of TIMES.
    def <<(times)
      r = times.shift
      @repeat += 1 if @times[:repeat].last != r
      @times[:repeat] << r
      TIMES.zip(times) { |t, time| @times[t] << time.to_f }
      self
    end

    # Returns a Hash of Sequence object for all of TIMES's time keys.
    def analysis
      @analysis ||= Hash.new do |h, time|
        time = time.to_sym
        times = @times[time]
        h[time] = MoreMath::Sequence.new(times)
      end
    end

    # Return true, if other's mean value is indistinguishable from this
    # object's mean after filtering out the noise from the measurements with a
    # Welch's t-Test. This mean's that differences in the mean of both clocks
    # might not inidicate a real performance difference and may be caused by
    # chance.
    def cover?(other)
      time = self.case.compare_time.to_sym
      analysis[time].cover?(other.analysis[time], self.case.covering.alpha_level.abs)
    end

    # Return column names in relation to Clock#to_a method.
    def self.to_a
      %w[ #scatter ] + TIMES + %w[ repeat ]
    end

    # Returns the measurements as an array of arrays.
    def to_a
      if @repeat >= 1
        (::Bullshit::Clock::ALL_COLUMNS).map do |t|
          analysis[t].elements
        end.transpose
      else
        []
      end
    end

    # Takes the times an returns an array, consisting of the times in the order
    # of enumerated in the TIMES constant.
    def take_time
      @time, times = Time.now, Process.times
      user_time = times.utime + times.cutime    # user time of this process and its children
      system_time = times.stime + times.cstime  # system time of this process and its children
      total_time = user_time + system_time      # total time of this process and its children
      [ @time.to_f, total_time, user_time, system_time ]
    end

    # Increment scatter counter by one.
    def inc_scatter
      @scatter += 1
    end

    # Take a single measurement. This method should be called with the code to
    # benchmark in a block.
    def measure
      before = take_time
      yield
      after = take_time
      @repeat += 1
      @times[:repeat] << @repeat
      @times[:scatter] << @scatter
      bs = self.case.batch_size.abs
      if bs and bs > 1
        TIMES.each_with_index { |t, i| @times[t] << (after[i] - before[i]) / bs }
      else
        TIMES.each_with_index { |t, i| @times[t] << after[i] - before[i] }
      end
      @analysis = nil
    end

    # Returns the sample standard deviation for the +time+ (one of TIMES'
    # symbols).
    def sample_standard_deviation(time)
      analysis[time.to_sym].sample_standard_deviation
    end

    # Returns the sample standard deviation for the +time+ (one of TIMES'
    # symbols) in percentage of its arithmetic mean.
    def sample_standard_deviation_percentage(time)
      analysis[time.to_sym].sample_standard_deviation_percentage
    end

    # Returns the minimum for the +time+ (one of TIMES' symbols).
    def min(time)
      analysis[time.to_sym].min
    end

    # Returns the maximum for the +time+ (one of TIMES' symbols).
    def max(time)
      analysis[time.to_sym].max
    end

    # Returns the median of the +time+ values (one of TIMES' symbols).
    def median(time)
      analysis[time.to_sym].median
    end

    # Returns the +p+-percentile of the +time+ values (one of TIMES' symbols).
    def percentile(time, p = 50)
      analysis[time.to_sym].percentile p
    end

    # Returns the q value for the Ljung-Box statistic of this +time+'s
    # analysis.detect_autocorrelation method.
    def detect_autocorrelation(time)
      analysis[time.to_sym].detect_autocorrelation(
        self.case.autocorrelation.max_lags.to_i,
        self.case.autocorrelation.alpha_level.abs)
    end

    # Return a result hash with the number of :very_low, :low, :high, and
    # :very_high outliers, determined by the box plotting algorithm run with
    # :median and :iqr parameters. If no outliers were found or the iqr is less
    # than epsilon, nil is returned.
    def detect_outliers(time)
      analysis[time.to_sym].detect_outliers(self.case.outliers_factor.abs)
    end

    TIMES.each do |time|
      define_method(time) { analysis[time].sum }
    end

    # Returns the sum of measurement times for +time+.
    def sum(time)
      __send__ time
    end

    # Seconds per call (mean)
    def call_time_mean
      mean(self.case.compare_time)
    end

    # Calls per second of the +call_time_type+, e. g. :call_time_mean or
    # :call_time_median.
    def calls(call_time_type)
      __send__(call_time_type) ** -1
    end

    # Calls per second (mean)
    def calls_mean
      call_time_mean ** -1
    end

    # Seconds per call (median)
    def call_time_median
      median(self.case.compare_time)
    end

    # Calls per second (median)
    def calls_median
      call_time_median ** -1
    end

    # Returns the arithmetic mean of +time+.
    def arithmetic_mean(time)
      analysis[time.to_sym].mean
    end

    alias mean arithmetic_mean

    # Returns the harmonic mean of +time+.
    def harmonic_mean(time)
      analysis[time.to_sym].harmonic_mean
    end

    # Returns the geometric mean of +time+.
    def geometric_mean(time)
      analysis[time.to_sym].geometric_mean
    end

    # The times which should be displayed in the output.
    def self.times
      TIMES.map { |t| t.to_s }
    end

    # Return the Histogram for the +time+ values.
    def histogram(time)
      analysis[time.to_sym].histogram(self.case.histogram.bins)
    end

    # Return the array of autocorrelation values for +time+.
    def autocorrelation(time)
      analysis[time.to_sym].autocorrelation
    end

    # Returns the arrays for the autocorrelation plot, the first array for the
    # numbers of lag measured, the second for the autocorrelation value.
    def autocorrelation_plot(time)
      r = autocorrelation time
      start = @times[:repeat].first
      ende = (start + r.size)
      (start...ende).to_a.zip(r)
    end

    # Return the result of CaseMethod#file_path for this clock's bc_method.
    def file_path(*args)
      @bc_method.file_path(*args)
    end

    # Truncate the measurements stored in this clock starting from the integer
    # +offset+.
    def truncate_data(offset)
      for t in ALL_COLUMNS
        times = @times[t]
        @times[t] = @times[t][offset, times.size]
        @repeat = @times[t].size
      end
      @analysis = nil
      self
    end

    # Find an offset from the start of the measurements in this clock to
    # truncate the initial data until a stable state has been reached and
    # return it as an integer.
    def find_truncation_offset
      truncation = self.case.truncate_data
      slope_angle = self.case.truncate_data.slope_angle.abs
      time = self.case.compare_time.to_sym
      ms = analysis[time].elements.reverse
      offset = ms.size - 1
      @slopes = []
      ModuleFunctions.array_window(ms, truncation.window_size) do |data|
        lr = LinearRegression.new(data)
        a = lr.a
        @slopes << [ offset, a ]
        a.abs > slope_angle and break
        offset -= 1
      end
      offset < 0 ? 0 : offset
    end
  end
end
