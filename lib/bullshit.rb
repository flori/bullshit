# = Bullshit - Benchmarking in Ruby
#
# == Description
#
# == Usage
#
# == Author
#
# Florian Frank mailto:flori@ping.de
#
# == License
#
# This is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License Version 2 as published by the Free
# Software Foundation: www.gnu.org/copyleft/gpl.html
#
# == Download
#
# The latest version of this library can be downloaded at
#
# * http://rubyforge.org/frs/?group_id=8323
#
# The homepage of this library is located at
#
# * http://bullshit.rubyforge.org
# 
# == Example
#

require 'dslkit'
require 'enumerator'

begin
  require 'bullshit/version'
rescue LoadError
end

# Module that includes all constants of the bullshit library.
module Bullshit
  COLUMNS = 79            # Number of columns in the output.

  NAME_COLUMN_SIZE = 5    # Number of columns used for row names.

  Infinity = 1.0 / 0      # Refers to floating point infinity.

  RUBY_DESCRIPTION = "ruby %s (%s patchlevel %s) [%s]" %
    [ RUBY_VERSION, RUBY_RELEASE_DATE, RUBY_PATCHLEVEL, RUBY_PLATFORM ]

  # This class implements a continued fraction of the form:
  #
  #                            b_1
  # a_0 + -------------------------
  #                            b_2
  #      a_1 + --------------------
  #                            b_3
  #           a_2 + ---------------
  #                            b_4
  #                a_3 + ----------
  #                            b_5
  #                     a_4 + -----
  #                            ...
  #
  class ContinuedFraction
    # Creates a continued fraction instance. With the defaults for_a { 1 } and
    # for_b { 1 } it approximates the golden ration phi if evaluated.
    def initialize
      @a = proc { 1.0 }
      @b = proc { 1.0 }
    end

    # Creates a ContinuedFraction instances and passes its arguments to a call
    # to for_a.
    def self.for_a(arg = nil, &block)
      new.for_a(arg, &block)
    end

    # Creates a ContinuedFraction instances and passes its arguments to a call
    # to for_b.
    def self.for_b(arg = nil, &block)
      new.for_b(arg, &block)
    end

    # This method either takes a block or an argument +arg+. The argument +arg+
    # has to respond to an integer index n >= 0 and return the value a_n. The
    # block has to return the value for a_n when +n+ is passed as the first
    # argument to the block. If a_n is dependent on an +x+ value (see the call
    # method) the +x+ will be the second argument of the block.
    def for_a(arg = nil, &block)
      if arg and !block
        @a = arg
      elsif block and !arg
        @a = block
      else
        raise ArgumentError, "exactly one argument or one block required"
      end
      self
    end

    # This method either takes a block or an argument +arg+. The argument +arg+
    # has to respond to an integer index n >= 1 and return the value b_n. The
    # block has to return the value for b_n when +n+ is passed as the first
    # argument to the block. If b_n is dependent on an +x+ value (see the call
    # method) the +x+ will be the second argument of the block.
    def for_b(arg = nil, &block)
      if arg and !block
        @b = arg
      elsif block and !arg
        @b = block
      else
        raise ArgumentError, "exactly one argument or one block required"
      end
      self
    end

    # Returns the value for a_n or a_n(x).
    def a(n, x = nil)
      result = if x
        @a[n, x]
      else
        @a[n]
      end and result.to_f
    end

    # Returns the value for b_n or b_n(x).
    def b(n, x = nil)
      result = if x
        @b[n, x]
      else
        @b[n]
      end and result.to_f
    end

    # Evaluates the continued fraction for the value +x+ (if any) with the
    # accuracy +epsilon+ and +max_iterations+ as the maximum number of
    # iterations using the Wallis-method with scaling.
    def call(x = nil, epsilon = 1E-16, max_iterations = 1 << 31)
      c_0, c_1 = 1.0, a(0, x)
      c_1 == nil and return 0 / 0.0
      d_0, d_1 = 0.0, 1.0
      result = c_1 / d_1
      n = 0
      error = 1 / 0.0
      $DEBUG and warn "n=%u, a=%f, b=nil, c=%f, d=%f result=%f, error=nil" %
        [ n, c_1, c_1, d_1, result ]
      while n < max_iterations and error > epsilon
        n += 1
        a_n, b_n = a(n, x), b(n, x)
        a_n and b_n or break
        c_2 = a_n * c_1 + b_n * c_0
        d_2 = a_n * d_1 + b_n * d_0
        if c_2.infinite? or d_2.infinite?
          if a_n != 0
            c_2 = c_1 + (b_n / a_n * c_0)
            d_2 = d_1 + (b_n / a_n * d_0)
          elsif b_n != 0
            c_2 = (a_n / b_n * c_1) + c_0
            d_2 = (a_n / b_n * d_1) + d_0
          else
            raise Errno::ERANGE
          end
        end
        r = c_2 / d_2
        error = (r / result - 1).abs

        result = r

        $DEBUG and warn "n=%u, a=%f, b=%f, c=%f, d=%f, result=%f, error=%.16f" %
          [ n, a_n, b_n, c_1, d_1, result, error ]

        c_0, c_1 = c_1, c_2
        d_0, d_1 = d_1, d_2
      end
      n >= max_iterations and raise Errno::ERANGE
      result
    end

    alias [] call

    # Returns this continued fraction as a Proc object which takes the same
    # arguments like its call method does.
    def to_proc
      proc { |*a| call(*a) }
    end
  end

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

  # An excpeption raised by the bullshit library.
  class BullshitException < StandardError; end

  # A Clock instance is used to take measurements while benchmarking.
  class Clock
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

    # Returns a Hash of Analysis object for all of TIMES's time keys.
    def analysis
      @analysis ||= Hash.new do |h, time|
        time = time.to_sym
        times = @times[time]
        h[time] = Analysis.new(times)
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
          analysis[t].measurements
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
      ms = analysis[time].measurements.reverse
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

  # A histogram gives an overview of measurement time values.
  class Histogram
    # Create a Histogram for +clock+ using the measurements for +time+.
    def initialize(analysis, bins)
      @analysis = analysis
      @bins = bins
      @result = compute
    end

    # Number of bins for this Histogram.
    attr_reader :bins

    # Return the computed histogram as an array of arrays.
    def to_a
      @result
    end

    # Display this histogram to +output+, +width+ is the parameter for
    # +prepare_display+
    def display(output = $stdout, width = 50)
      d = prepare_display(width)
      for l, bar, r in d
        output << "%11.5f -|%s\n" % [ (l + r) / 2.0, "*" * bar ]
      end
      self
    end

    private

    # Returns an array of tuples (l, c, r) where +l+ is the left bin edge, +c+
    # the +width+-normalized frequence count value, and +r+ the right bin
    # edge. +width+ is usually an integer number representing the width of a
    # histogram bar.
    def prepare_display(width)
      r = @result.reverse
      factor = width.to_f / (r.transpose[1].max)
      r.map { |l, c, r| [ l, (c * factor).round, r ] }
    end

    # Computes the histogram and returns it as an array of tuples (l, c, r).
    def compute
      @analysis.measurements.empty? and return []
      last_r = -Infinity
      min = @analysis.min
      max = @analysis.max
      step = (max - min) / bins.to_f
      Array.new(bins) do |i|
        l = min + i  * step
        r = min + (i + 1) * step
        c = 0
        @analysis.measurements.each do |x|
          x > last_r and (x <= r || i == bins - 1) and c += 1
        end
        last_r = r
        [ l, c, r ]
      end
    end
  end

  # This class is used to find the root of a function with Newton's bisection
  # method.
  class NewtonBisection
    # Creates a NewtonBisection instance for +function+, a one-argument block.
    def initialize(&function)
      @function = function
    end

    # The function, passed into the constructor.
    attr_reader :function

    # Return a bracket around a root, starting from the initial +range+. The
    # method returns nil, if no such bracket around a root could be found after
    # +n+ tries with  the scaling +factor+.
    def bracket(range = -1..1, n = 50, factor =  1.6)
      x1, x2 = range.first.to_f, range.last.to_f
      x1 >= x2 and raise ArgumentError, "bad initial range #{range}"
      f1, f2 = @function[x1], @function[x2]
      n.times do
        f1 * f2 < 0 and return x1..x2
        if f1.abs < f2.abs
          f1 = @function[x1 += factor * (x1 - x2)]
        else
          f2 = @function[x2 += factor * (x2 - x1)]
        end
      end
      return
    end

    # Find the root of function in +range+ and return it. The method raises a
    # BullshitException, if no such root could be found after +n+ tries and in
    # the +epsilon+ environment.
    def solve(range = nil, n = 1 << 16, epsilon = 1E-16)
      if range
        x1, x2 = range.first.to_f, range.last.to_f
        x1 >= x2 and raise ArgumentError, "bad initial range #{range}"
      elsif range = bracket
        x1, x2 = range.first, range.last
      else
        raise ArgumentError, "bracket could not be determined"
      end
      f = @function[x1]
      fmid = @function[x2]
      f * fmid >= 0 and raise ArgumentError, "root must be bracketed in #{range}"
      root = if f < 0
               dx = x2 - x1
               x1
             else
               dx = x1 - x2
               x2
             end
      n.times do
        fmid = @function[xmid = root + (dx *= 0.5)]
        fmid < 0 and root = xmid
        dx.abs < epsilon or fmid == 0 and return root
      end
      raise BullshitException, "too many iterations (#{n})"
    end
  end

  module Functions
    module_function

    include Math
    extend Math

    LANCZOS_COEFFICIENTS = [
      0.99999999999999709182,
      57.156235665862923517,
      -59.597960355475491248,
      14.136097974741747174,
      -0.49191381609762019978,
      0.33994649984811888699e-4,
      0.46523628927048575665e-4,
      -0.98374475304879564677e-4,
      0.15808870322491248884e-3,
      -0.21026444172410488319e-3,
      0.21743961811521264320e-3,
      -0.16431810653676389022e-3,
      0.84418223983852743293e-4,
      -0.26190838401581408670e-4,
      0.36899182659531622704e-5,
    ]

    HALF_LOG_2_PI = 0.5 * log(2 * Math::PI)

    # Returns the natural logarithm of Euler gamma function value for +x+ using
    # the Lanczos approximation.
    if method_defined?(:lgamma)
      def log_gamma(x)
        lgamma(x).first
      end
    else
      def log_gamma(x)
        if x.nan? || x <= 0
          0 / 0.0
        else
          sum = 0.0
          (LANCZOS_COEFFICIENTS.size - 1).downto(1) do |i|
            sum += LANCZOS_COEFFICIENTS[i] / (x + i)
          end
          sum += LANCZOS_COEFFICIENTS[0]
          tmp = x + 607.0 / 128 + 0.5
          (x + 0.5) * log(tmp) - tmp + HALF_LOG_2_PI + log(sum / x)
        end
      rescue Errno::ERANGE, Errno::EDOM
        0 / 0.0
      end
    end

    # Returns the natural logarithm of the beta function value for +(a, b)+.
    def log_beta(a, b)
      log_gamma(a) + log_gamma(b) - log_gamma(a + b)
    rescue Errno::ERANGE, Errno::EDOM
      0 / 0.0
    end

    # Return an approximation value of Euler's regularized beta function for
    # +x+, +a+, and +b+ with an error <= +epsilon+, but only iterate
    # +max_iterations+-times.
    def beta_regularized(x, a, b, epsilon = 1E-16, max_iterations = 1 << 16)
      x, a, b = x.to_f, a.to_f, b.to_f
      case
      when a.nan? || b.nan? || x.nan? || a <= 0 || b <= 0 || x < 0 || x > 1
        0 / 0.0
      when x > (a + 1) / (a + b + 2)
        1 - beta_regularized(1 - x, b, a, epsilon, max_iterations)
      else
        fraction = ContinuedFraction.for_b do |n, x|
          if n % 2 == 0
            m = n / 2.0
            (m * (b - m) * x) / ((a + (2 * m) - 1) * (a + (2 * m)))
          else
            m = (n - 1) / 2.0
            -((a + m) * (a + b + m) * x) / ((a + 2 * m) * (a + 2 * m + 1))
          end
        end
        exp(a * log(x) + b * log(1.0 - x) - log(a) - log_beta(a, b)) / 
          fraction[x, epsilon, max_iterations]
      end
    rescue Errno::ERANGE, Errno::EDOM
      0 / 0.0
    end

    # Return an approximation of the regularized gammaP function for +x+ and
    # +a+ with an error of <= +epsilon+, but only iterate
    # +max_iterations+-times.
    def gammaP_regularized(x, a, epsilon = 1E-16, max_iterations = 1 << 16)
      x, a = x.to_f, a.to_f
      case
      when a.nan? || x.nan? || a <= 0 || x < 0
        0 / 0.0
      when x == 0
        0.0
      when 1 <= a && a < x
        1 - gammaQ_regularized(x, a, epsilon, max_iterations)
      else
        n = 0
        an = 1 / a
        sum = an
        while an.abs > epsilon && n < max_iterations
          n += 1
          an *= x / (a + n)
          sum += an
        end
        if n >= max_iterations
          raise Errno::ERANGE
        else
          exp(-x + a * log(x) - log_gamma(a)) * sum
        end
      end
    rescue Errno::ERANGE, Errno::EDOM
      0 / 0.0
    end

    # Return an approximation of the regularized gammaQ function for +x+ and
    # +a+ with an error of <= +epsilon+, but only iterate
    # +max_iterations+-times.
    def gammaQ_regularized(x, a, epsilon = 1E-16, max_iterations = 1 << 16)
      x, a = x.to_f, a.to_f
      case
      when a.nan? || x.nan? || a <= 0 || x < 0
        0 / 0.0
      when x == 0
        1.0
      when a > x || a < 1
        1 - gammaP_regularized(x, a, epsilon, max_iterations)
      else
        fraction = ContinuedFraction.for_a do |n, x|
          (2 * n + 1) - a + x
        end.for_b do |n, x|
          n * (a - n)
        end
        exp(-x + a * log(x) - log_gamma(a)) *
          fraction[x, epsilon, max_iterations] ** -1
      end
    rescue Errno::ERANGE, Errno::EDOM
      0 / 0.0
    end

    ROOT2 = sqrt(2)

    A = -8 * (Math::PI - 3) / (3 * Math::PI * (Math::PI - 4))

    # Returns an approximate value for the error function's value for +x+.
    def erf(x)
      r = sqrt(1 - exp(-x ** 2 * (4 / Math::PI + A * x ** 2) / (1 + A * x ** 2)))
      x < 0 ? -r : r
    end unless method_defined?(:erf)
  end

  # This class is used to compute the T-Distribution.
  class TDistribution
    include Functions

    # Returns a TDistribution instance for the degrees of freedom +df+.
    def initialize(df)
      @df = df
    end

    # Degrees of freedom.
    attr_reader :df

    # Returns the cumulative probability (p-value) of the TDistribution for the
    # t-value +x+.
    def probability(x)
      if x == 0
        0.5
      else
        t = beta_regularized(@df / (@df + x ** 2.0), 0.5 * @df, 0.5)
        if x < 0.0
          0.5 * t
        else
          1 - 0.5 * t
        end
      end
    end
   
    # Returns the inverse cumulative probability (t-value) of the TDistribution
    # for the probability +p+.
    def inverse_probability(p)
      case
      when p <= 0
        -1 / 0.0
      when p >= 1
        1 / 0.0
      else 
        begin
          bisect = NewtonBisection.new { |x| probability(x) - p }
          range = bisect.bracket(-10..10)
          bisect.solve(range, 1_000_000)
        rescue
          0 / 0.0
        end
      end
    end
  end

  # This class is used to compute the Normal Distribution.
  class NormalDistribution
    include Functions

    # Creates a NormalDistribution instance for the values +mu+ and +sigma+.
    def initialize(mu = 0.0, sigma = 1.0)
      @mu, @sigma = mu.to_f, sigma.to_f
    end

    attr_reader :mu

    attr_reader :sigma

    # Returns the cumulative probability (p-value) of the NormalDistribution
    # for the value +x+.
    def probability(x)
      0.5 * (1 + erf((x - @mu) / (@sigma * ROOT2)))
    end

    # Returns the inverse cumulative probability value of the
    # NormalDistribution for the probability +p+.
    def inverse_probability(p)
      case
      when p <= 0
        -1 / 0.0
      when p >= 1
        1 / 0.0
      when p == 0.5 # This is a bit sloppy, maybe improve this later.
        @mu
      else
        begin
          NewtonBisection.new { |x| probability(x) - p }.solve(nil, 1_000_000)
        rescue
          0 / 0.0
        end
      end
    end
  end

  STD_NORMAL_DISTRIBUTION = NormalDistribution.new

  # This class is used to compute the Chi-Square Distribution.
  class ChiSquareDistribution
    include Functions

    # Creates a ChiSquareDistribution for +df+ degrees of freedom.
    def initialize(df)
      @df = df
      @df_half = @df / 2.0
    end

    attr_reader :df

    # Returns the cumulative probability (p-value) of the ChiSquareDistribution
    # for the value +x+.
    def probability(x)
      if x < 0
        0.0
      else
        gammaP_regularized(x / 2, @df_half)
      end
    end

    # Returns the inverse cumulative probability value of the
    # NormalDistribution for the probability +p+.
    def inverse_probability(p)
      case
      when p <= 0, p >= 1
        0.0
      else
        begin
          bisect = NewtonBisection.new { |x| probability(x) - p }
          range = bisect.bracket 0.5..10
          bisect.solve(range, 1_000_000)
        rescue
          0 / 0.0
        end
      end
    end
  end

  # This class computes a linear regression for the given image and domain data
  # sets.
  class LinearRegression
    def initialize(image, domain = (0...image.size).to_a)
      image.size != domain.size and raise ArgumentError,
        "image and domain have unequal sizes"
      @image, @domain = image, domain
      compute
    end

    # The image data as an array.
    attr_reader :image

    # The domain data as an array.
    attr_reader :domain

    # The slope of the line.
    attr_reader :a

    # The offset of the line.
    attr_reader :b

    # Return true if the slope of the underlying data (not the sample data
    # passed into the constructor of this LinearRegression instance) is likely
    # (with alpha level _alpha_) to be zero.
    def slope_zero?(alpha = 0.05)
      df = @image.size - 2
      return true if df <= 0 # not enough values to check
      t = tvalue(alpha)
      td = TDistribution.new df
      t.abs <= td.inverse_probability(1 - alpha.abs / 2.0).abs
    end

    # Returns the residues of this linear regression in relation to the given
    # domain and image.
    def residues
      result = []
      @domain.zip(@image) do |x, y|
        result << y - (@a * x + @b)
      end
      result
    end

    private

    def compute
      size = @image.size
      sum_xx = sum_xy = sum_x = sum_y = 0.0
      @domain.zip(@image) do |x, y|
        x += 1
        sum_xx += x ** 2
        sum_xy += x * y
        sum_x += x
        sum_y += y
      end
      @a = (size * sum_xy - sum_x * sum_y) / (size * sum_xx - sum_x ** 2)
      @b = (sum_y - @a * sum_x) / size
      self
    end

    def tvalue(alpha = 0.05)
      df = @image.size - 2
      return 0.0 if df <= 0
      sse_y = 0.0
      @domain.zip(@image) do |x, y|
        f_x = a * x + b
        sse_y += (y - f_x) ** 2
      end
      mean = @image.inject(0.0) { |s, y| s + y } / @image.size
      sse_x = @domain.inject(0.0) { |s, x| s + (x - mean) ** 2 }
      t = a / (Math.sqrt(sse_y / df) / Math.sqrt(sse_x))
      t.nan? ? 0.0 : t
    end
  end

  # This class is used to analyse the time measurements and compute their
  # statistics.
  class Analysis
    def initialize(measurements)
      @measurements = measurements
      @measurements.freeze
    end

    # Returns the array of measurements.
    attr_reader :measurements

    # Returns the number of measurements, on which the analysis is based.
    def size
      @measurements.size
    end

    # Returns the variance of the measurements.
    def variance
      @variance ||= sum_of_squares / size
    end

    # Returns the sample_variance of the measurements.
    def sample_variance
      @sample_variance ||= size > 1 ? sum_of_squares / (size - 1.0) : 0.0
    end

    # Returns the sum of squares (the sum of the squared deviations) of the
    # measurements.
    def sum_of_squares
      @sum_of_squares ||= @measurements.inject(0.0) { |s, t| s + (t - arithmetic_mean) ** 2 }
    end

    # Returns the standard deviation of the measurements.
    def standard_deviation
      @sample_deviation ||= Math.sqrt(variance)
    end

    # Returns the standard deviation of the measurements in percentage of the
    # arithmetic mean.
    def standard_deviation_percentage
      @standard_deviation_percentage ||= 100.0 * standard_deviation / arithmetic_mean
    end

    # Returns the sample standard deviation of the measurements.
    def sample_standard_deviation
      @sample_standard_deviation ||= Math.sqrt(sample_variance)
    end

    # Returns the sample standard deviation of the measurements in percentage
    # of the arithmetic mean.
    def sample_standard_deviation_percentage
      @sample_standard_deviation_percentage ||= 100.0 * sample_standard_deviation / arithmetic_mean
    end

    # Returns the sum of all measurements.
    def sum
      @sum ||= @measurements.inject(0.0) { |s, t| s + t }
    end

    # Returns the arithmetic mean of the measurements.
    def arithmetic_mean
      @arithmetic_mean ||= sum / size
    end

    alias mean arithmetic_mean

    # Returns the harmonic mean of the measurements. If any of the measurements
    # is less than or equal to 0.0, this method returns NaN.
    def harmonic_mean
      @harmonic_mean ||= (
        sum = @measurements.inject(0.0) { |s, t|
          if t > 0
            s + 1.0 / t
          else
            break nil
          end
        }
        sum ? size / sum : 0 / 0.0
      )
    end

    # Returns the geometric mean of the measurements. If any of the
    # measurements is less than 0.0, this method returns NaN.
    def geometric_mean
      @geometric_mean ||= (
        sum = @measurements.inject(0.0) { |s, t|
          case
          when t > 0
            s + Math.log(t)
          when t == 0
            break :null
          else
            break nil
          end
        }
        case sum
        when :null
          0.0
        when Float
          Math.exp(sum / size)
        else
          0 / 0.0
        end
      )
    end

    # Returns the minimum of the measurements.
    def min
      @min ||= @measurements.min
    end

    # Returns the maximum of the measurements.
    def max
      @max ||= @measurements.max
    end

    # Returns the +p+-percentile of the measurements.
    # There are many methods to compute the percentile, this method uses the
    # the weighted average at x_(n + 1)p, which allows p to be in 0...100
    # (excluding the 100).
    def percentile(p = 50)
      (0...100).include?(p) or
        raise ArgumentError, "p = #{p}, but has to be in (0...100)"
      p /= 100.0
      @sorted ||= @measurements.sort
      r = p * (@sorted.size + 1)
      r_i = r.to_i
      r_f = r - r_i
      if r_i >= 1
        result = @sorted[r_i - 1]
        if r_i < @sorted.size
          result += r_f * (@sorted[r_i] - @sorted[r_i - 1])
        end
      else
        result = @sorted[0]
      end
      result
    end

    alias median percentile

    # Use an approximation of the Welch-Satterthwaite equation to compute the
    # degrees of freedom for Welch's t-test.
    def compute_welch_df(other)
      (sample_variance / size + other.sample_variance / other.size) ** 2 / (
        (sample_variance ** 2 / (size ** 2 * (size - 1))) +
        (other.sample_variance ** 2 / (other.size ** 2 * (other.size - 1))))
    end

    # Returns the t value of the Welch's t-test between this Analysis
    # instance and the +other+.
    def t_welch(other)
      signal = arithmetic_mean - other.arithmetic_mean
      noise = Math.sqrt(sample_variance / size +
        other.sample_variance / other.size)
      signal / noise
    rescue Errno::EDOM
      0.0
    end

    # Returns an estimation of the common standard deviation of the
    # measurements of this and +other+.
    def common_standard_deviation(other)
      Math.sqrt(common_variance(other))
    end

    # Returns an estimation of the common variance of the measurements of this
    # and +other+.
    def common_variance(other)
      (size - 1) * sample_variance + (other.size - 1) * other.sample_variance /
        (size + other.size - 2)
    end

    # Compute the # degrees of freedom for Student's t-test.
    def compute_student_df(other)
      size + other.size - 2
    end

    # Returns the t value of the Student's t-test between this Analysis
    # instance and the +other+.
    def t_student(other)
      signal = arithmetic_mean - other.arithmetic_mean
      noise = common_standard_deviation(other) *
        Math.sqrt(size ** -1 + size ** -1)
    rescue Errno::EDOM
      0.0
    end

    # Compute a sample size, that will more likely yield a mean difference
    # between this instance's measurements and those of +other+. Use +alpha+
    # and +beta+ as levels for the first- and second-order errors.
    def suggested_sample_size(other, alpha = 0.05, beta = 0.05)
      alpha, beta = alpha.abs, beta.abs
      signal = arithmetic_mean - other.arithmetic_mean
      df = size + other.size - 2
      pooled_variance_estimate = (sum_of_squares + other.sum_of_squares) / df
      td = TDistribution.new df
      (((td.inverse_probability(alpha) + td.inverse_probability(beta)) *
        Math.sqrt(pooled_variance_estimate)) / signal) ** 2
    end

    # Return true, if the Analysis instance covers the +other+, that is their
    # arithmetic mean value is most likely to be equal for the +alpha+ error
    # level.
    def cover?(other, alpha = 0.05)
      t = t_welch(other)
      td = TDistribution.new(compute_welch_df(other))
      t.abs < td.inverse_probability(1 - alpha.abs / 2.0)
    end

    # Return the confidence interval for the arithmetic mean with alpha level +alpha+ of
    # the measurements of this Analysis instance as a Range object.
    def confidence_interval(alpha = 0.05)
      td = TDistribution.new(size - 1)
      t = td.inverse_probability(alpha / 2).abs
      delta = t * sample_standard_deviation / Math.sqrt(size)
      (arithmetic_mean - delta)..(arithmetic_mean + delta)
    end

    # Returns the array of autovariances (of length size - 1).
    def autovariance
      Array.new(size - 1) do |k|
        s = 0.0
        0.upto(size - k - 1) do |i|
          s += (@measurements[i] - arithmetic_mean) * (@measurements[i + k] - arithmetic_mean)
        end
        s / size
      end
    end

    # Returns the array of autocorrelation values c_k / c_0 (of length size -
    # 1).
    def autocorrelation
      c = autovariance
      Array.new(c.size) { |k| c[k] / c[0] }
    end

    # Returns the d-value for the Durbin-Watson statistic. The value is d << 2
    # for positive, d >> 2 for negative and d around 2 for no autocorrelation.
    def durbin_watson_statistic
      e = linear_regression.residues
      e.size <= 1 and return 2.0
      (1...e.size).inject(0.0) { |s, i| s + (e[i] - e[i - 1]) ** 2 } /
        e.inject(0.0) { |s, x| s + x ** 2 }
    end

    # Returns the q value of the Ljung-Box statistic for the number of lags
    # +lags+. A higher value might indicate autocorrelation in the measurements of
    # this Analysis instance. This method returns nil if there weren't enough
    # (at least lags) lags available.
    def ljung_box_statistic(lags = 20)
      r = autocorrelation
      lags >= r.size and return
      n = size
      n * (n + 2) * (1..lags).inject(0.0) { |s, i| s + r[i] ** 2 / (n - i) }
    end

    # This method tries to detect autocorrelation with the Ljung-Box
    # statistic. If enough lags can be considered it returns a hash with
    # results, otherwise nil is returned. The keys are
    #   :lags: the number of lags,
    #   :alpha_level: the alpha level for the test,
    #   :q: the value of the ljung_box_statistic,
    #   :p: the p-value computed, if p is higher than alpha no correlation was detected,
    #   :detected: true if a correlation was found.
    def detect_autocorrelation(lags = 20, alpha_level = 0.05)
      if q = ljung_box_statistic(lags)
        p = ChiSquareDistribution.new(lags).probability(q)
        return {
          :lags         => lags,
          :alpha_level  => alpha_level,
          :q            => q,
          :p            => p,
          :detected     => p >= 1 - alpha_level,
        }
      end
    end

    # Return a result hash with the number of :very_low, :low, :high, and
    # :very_high outliers, determined by the box plotting algorithm run with
    # :median and :iqr parameters. If no outliers were found or the iqr is
    # less than epsilon, nil is returned.
    def detect_outliers(factor = 3.0, epsilon = 1E-5)
      half_factor = factor / 2.0
      quartile1 = percentile(25)
      quartile3 = percentile(75)
      iqr = quartile3 - quartile1
      iqr < epsilon and return
      result = @measurements.inject(Hash.new(0)) do |h, t|
        extreme =
          case t
          when -Infinity..(quartile1 - factor * iqr)
            :very_low
          when (quartile1 - factor * iqr)..(quartile1 - half_factor * iqr)
            :low
          when (quartile1 + half_factor * iqr)..(quartile3 + factor * iqr)
            :high
          when (quartile3 + factor * iqr)..Infinity
            :very_high
          end and h[extreme] += 1
        h
      end
      unless result.empty?
        result[:median] = median
        result[:iqr] = iqr
        result[:factor] = factor
        result
      end
    end

    # Returns the LinearRegression object for the equation a * x + b which
    # represents the line computed by the linear regression algorithm.
    def linear_regression
      @linear_regression ||= LinearRegression.new @measurements
    end

    # Returns a Histogram instance with +bins+ as the number of bins for this
    # analysis' measurements.
    def histogram(bins)
      Histogram.new(self, bins)
    end
  end

  CaseMethod = Struct.new(:name, :case, :clock)

  # This class' instance represents a method to be benchmarked.
  class CaseMethod
    # Return the short name of this CaseMethod instance, that is without the
    # "benchmark_" prefix, e. g. "foo".
    def short_name
      @short_name ||= name.sub(/\Abenchmark_/, '')
    end

    # The comment for this method.
    attr_accessor :comment

    # Returns the long_name of this CaseMethod of the form Foo#bar.
    def long_name
      result = "#{self.case}##{short_name}"
      result = "#{result} (#{comment})" if comment
      result
    end

    # Return the setup_name, e. g. "setup_foo".
    def setup_name
      'setup_' + short_name
    end

    # Return the before_name, e. g. "before_foo".
    def before_name
      'before_' + short_name
    end
    
    # Return the after_name, e. g. "after_foo".
    def after_name
      'after_' + short_name
    end

    # Return the teardown_name, e. g. "teardown_foo".
    def teardown_name
      'teardown_' + short_name
    end

    # Return true if this CaseMethod#clock covers other.clock.
    def cover?(other)
      clock.cover?(other.clock)
    end

    # Call before method of this CaseMethod before benchmarking it.
    def before_run
      if self.case.respond_to? before_name
        $DEBUG and warn "Calling #{before_name}."
        self.case.__send__(before_name)
      end
    end

    # Call after method of this CaseMethod after benchmarking it.
    def after_run
      if self.case.respond_to? after_name
        $DEBUG and warn "Calling #{after_name}."
        self.case.__send__(after_name)
      end
    end

    # Return the file name for +type+ with +suffix+ (if any) for this clock.
    def file_path(type = nil, suffix = '.dat')
      name = self.case.class.benchmark_name.dup
      name << '#' << short_name
      type and name << '-' << type
      name << suffix
      File.expand_path(name, self.case.class.output_dir)
    end

    # Load the data of file +fp+ into this clock.
    def load(fp = file_path)
      self.clock = self.case.class.clock.new self
      $DEBUG and warn "Loading '#{fp}' into clock."
      File.open(fp, 'r') do |f|
        f.each do |line|
          line.chomp!
          line =~ /^\s*#/ and next
          clock << line.split(/\t/)
        end
      end
      self
    rescue Errno::ENOENT
    end

    alias to_s long_name
  end

  module CommonConstants
    extend DSLKit::Constant

    constant :yes, true      

    constant :no, false
  end

  # This is the base class of all Benchmarking Cases.
  class Case

    # All subclasses of Case are extended with this module.
    module CaseExtension
      def inherited(klass)
        Case.cases << klass
      end

      extend DSLKit::DSLAccessor
      extend DSLKit::Constant

      include CommonConstants

      dsl_accessor :benchmark_name do name end

      dsl_accessor :clock, Clock

      constant :real

      constant :total

      constant :user

      constant :system

      dsl_accessor :compare_time, :real

      dsl_accessor :warmup, false

      dsl_accessor :batch_size, 1

      class TruncateData
        extend DSLKit::DSLAccessor
        extend DSLKit::Constant

        include CommonConstants
        include ModuleFunctions

        dsl_accessor :alpha_level, 0.05

        dsl_accessor :window_size, 10

        dsl_accessor :slope_angle, ModuleFunctions.angle(0.1)

        dsl_accessor :enabled, false

        def initialize(enable, &block)
          if block
            enable.nil? or raise ArgumentError, "block form doesn't take an argument"
            instance_eval(&block)
            enabled true
          else
            enabled enable.nil? ? false : enable
          end
        end
      end

      def truncate_data(enable = nil, &block)
        @truncate_data ||= TruncateData.new(enable, &block)
      end

      constant :aggressive, :aggressive

      class Covering
        extend DSLKit::DSLAccessor

        dsl_accessor :alpha_level, 0.05

        dsl_accessor :beta_level, 0.05

        def initialize(&block)
          block and instance_eval(&block)
        end
      end

      def covering(&block)
        @covering = Covering.new(&block)
      end

      dsl_accessor :data_file, false

      dsl_accessor :output_dir, Dir.pwd

      class Histogram
        extend DSLKit::DSLAccessor
        extend DSLKit::Constant

        include CommonConstants

        dsl_accessor :bins, 10

        dsl_accessor :enabled, false

        dsl_accessor :file, false

        def initialize(enable = nil, &block)
          if block
            enable.nil? or raise ArgumentError, "block form doesn't take an argument"
            instance_eval(&block)
            enabled true
          else
            enabled enable.nil? ? true : enable
          end
        end
      end

      def histogram(enable = nil, &block)
        @histogram ||= Histogram.new(enable, &block)
      end

      dsl_accessor :detect_outliers, true

      dsl_accessor :outliers_factor, 3.0

      class Autocorrelation
        extend DSLKit::DSLAccessor
        extend DSLKit::Constant

        include CommonConstants

        dsl_accessor :n_limit, 50

        dsl_accessor :alpha_level, 0.05

        dsl_accessor :max_lags, 20

        dsl_accessor :enabled, false

        dsl_accessor :file, true

        def initialize(enable = nil, &block)
          if block
            enable.nil? or raise ArgumentError, "block form doesn't take an argument"
            instance_eval(&block)
            enabled true
          else
            enabled enable.nil? ? false : enable
          end
        end
      end

      def autocorrelation(enable = nil, &block)
        @autocorrelation ||= Autocorrelation.new(enable, &block)
      end

      dsl_accessor :linear_regression, true
      
      include ModuleFunctions
    end

    class << self
      def inherited(klass)
        klass.extend CaseExtension
      end

      extend DSLKit::DSLAccessor

      dsl_reader :cases, []

      dsl_accessor :output, STDOUT

      def output_filename(name)
        path = File.expand_path(name, output_dir)
        output File.new(path, 'a+')
      end

      # Returns the total number of run counts +run_count+.
      def run_count
        cases.inject(0) { |s, c| s + c.run_count }
      end

      dsl_accessor :autorun, true

      # Iterate over all subclasses of class Case.
      def each(&block)
        cases.each(&block)
      end

      # Run all subclasses' instances, that is all Bullshit cases, unless they
      # already have run.
      def run_all
        each do |bc_class|
          bc_class.run_count == 0 and bc_class.run
        end
      end

      # Autorun all subclasses' instances, that is all Bullshit cases. If its
      # autorun dsl_accessor is false or it has already run, don't run the
      # case.
      def autorun_all
        each do |bc_class|
          bc_class.autorun and bc_class.run_count == 0 and bc_class.run
        end
      end
    end

    # Returns a Case instance, that is used to run benchmark methods and
    # measure their running time.
    def initialize
      @clocks = []
      @comparison = Comparison.new
      @comparison.output self.class.output
    end

    # Return the name of the benchmark case as a string.
    def to_s
      self.class.benchmark_name
    end

    # Return all benchmark methods of this Case instance lexicographically
    # sorted.
    def self.sorted_bmethods
      instance_methods.map { |x| x.to_s }.grep(/\Abenchmark_/).sort
    end

    # Return all benchmark methods of this Case instance in a random order.
    def bmethods
      unless @bmethods
        @bmethods = self.class.sorted_bmethods.sort_by do
          rand
        end
        @bmethods.map! { |n| CaseMethod.new(n, self) }
      end
      @bmethods
    end

    # Return the CaseMethod instance for +method_name+ or nil, if there isn't
    # any method of this name.
    def [](method_name)
      method_name = "benchmark_#{method_name}"
      bmethods.find { |bm| bm.name == method_name }
    end

    # Return the length of the longest_name of all these methods' names.
    def longest_name
      bmethods.empty? and return 0
      bmethods.map { |x| x.short_name.size }.max
    end

    # Run benchmark case once and output results.
    def run_once
      self.class.run_count(self.class.run_count + 1)
      self.class.output.puts Time.now.strftime(' %FT%T %Z ').center(COLUMNS, '=')
      self.class.output.puts "Benchmarking on #{RUBY_DESCRIPTION}."
      self.class.output.puts self.class.message
      self.class.output.puts '=' * COLUMNS, ''
      @clocks.clear
      if self.class.warmup == :aggressive
        self.class.output.puts "Aggressively run all benchmarks for warmup first.", ''
        bmethods.each do |bc_method|
          GC.start
          clock = run_method bc_method
          self.class.output.puts evaluation(clock)
          GC.start
        end
        self.class.output.puts "Aggressive warmup done.", '', '=' * COLUMNS, ''
      end
      first = true
      bmethods.each do |bc_method|
        if first
          first = false
        else
          self.class.output.puts '-' * COLUMNS, ''
        end
        if self.class.warmup
          self.class.output.puts "This first run is only for warmup."
          GC.start
          clock = run_method bc_method
          self.class.output.puts evaluation(clock)
          GC.start
        end
        clock = run_method(bc_method)
        if self.class.truncate_data.enabled
          message = ''
          offset = clock.find_truncation_offset
          if clock.case.data_file
            slopes_file_path = clock.file_path 'slopes'
            message << "Writing slopes data file '#{slopes_file_path}'.\n"
            File.open(slopes_file_path, 'w') do |slopes_file|
              slopes_file.puts %w[#scatter slope] * "\t"
              slopes_file.puts clock.slopes.map { |s| s * "\t" }
            end
          end
          case offset
          when 0
            message << "No initial data truncated.\n =>"\
              " System may have been in a steady state from the beginning."
          when clock.repeat
            message << "After truncating measurements no data would have"\
              " remained.\n => No steady state could be detected."
          else
            if clock.case.data_file
              data_file_path = clock.file_path 'untruncated'
              message << "Writing untruncated measurement data file '#{data_file_path}'.\n"
              File.open(data_file_path, 'w') do |data_file|
                data_file.puts clock.class.to_a * "\t"
                data_file.puts clock.to_a.map { |times| times * "\t" }
              end
            end
            remaining = clock.repeat - offset
            offset_percentage = 100 * offset.to_f / clock.repeat
            message << sprintf("Truncated initial %u measurements: "\
              "%u -> %u (-%0.2f%%).\n", offset, clock.repeat, remaining,
              offset_percentage)
            clock.truncate_data(offset)
          end
          self.class.output.puts evaluation(clock), message
        else
          self.class.output.puts evaluation(clock)
        end
        @clocks << clock
        @comparison.benchmark(self, bc_method.short_name, :run => false)
      end
      @clocks
    end

    # The clock instances, that were used during a run of this benchmark case.
    attr_reader :clocks

    # Setup, run all benchmark cases (warmup and the real run) and output
    # results, run method speed comparisons, and teardown.
    def run(comparison = true)
      old_sync, self.class.output.sync = self.class.output.sync, true
      $DEBUG and warn "Calling setup."
      setup
      run_once
      comparison and @comparison.display
      self
    rescue => e
      warn "Caught #{e.class}: #{e}\n\n#{e.backtrace.map { |x| "\t#{x}\n" }}"
    ensure
      $DEBUG and warn "Calling teardown."
      teardown
      @clocks and write_files
      self.class.output.sync = old_sync
    end

    # Creates an instance of this class and run it.
    def self.run
      new.run
    end

    # Write all output files after run.
    def write_files
      for clock in @clocks
        if clock.case.data_file data_file_path = clock.file_path
          self.class.output.puts "Writing measurement data file '#{data_file_path}'."
          File.open(data_file_path, 'w') do |data_file|
            data_file.puts clock.class.to_a * "\t"
            data_file.puts clock.to_a.map { |times| times * "\t" }
          end
        end
        if clock.case.histogram.enabled and clock.case.histogram.file
          histogram_file_path = clock.file_path 'histogram'
          self.class.output.puts "Writing histogram file '#{histogram_file_path}'."
          File.open(histogram_file_path, 'w') do |data_file|
            data_file.puts %w[#binleft frequency binright] * "\t"
            data_file.puts clock.histogram(clock.case.compare_time).to_a.map { |times| times * "\t" }
          end
        end
        if clock.case.autocorrelation.enabled and clock.case.autocorrelation.file
          ac_plot_file_path = clock.file_path 'autocorrelation'
          self.class.output.puts "Writing autocorrelation plot file '#{ac_plot_file_path}'."
          File.open(ac_plot_file_path, 'w') do |data_file|
            data_file.puts %w[#lag autocorrelation] * "\t"
            data_file.puts clock.autocorrelation_plot(clock.case.compare_time).to_a.map { |ac| ac * "\t" }
          end
        end
      end
    end

    # Output before +bc_method+ is run.
    def pre_run(bc_method)
      setup_name = bc_method.setup_name
      if respond_to? setup_name
        $DEBUG and warn "Calling #{setup_name}."
        __send__(setup_name)
      end
      self.class.output.puts "#{bc_method.long_name}:"
    end

    # Run only pre_run and post_run methods. Yield to the block, if one was
    # given.
    def run_method(bc_method)
      pre_run bc_method
      clock = self.class.clock.__send__(self.class.clock_method, bc_method) do
        __send__(bc_method.name)
      end
      bc_method.clock = clock
      post_run bc_method
      clock
    end

    # This method has to be implemented in subclasses, it should return the
    # evaluation results of the benchmarks as a string.
    def evaluation(clock)
      raise NotImplementedError, "has to be implemented in subclasses"
    end

    # Output after +bc_method+ is run.
    def post_run(bc_method)
      teardown_name = bc_method.teardown_name
      if respond_to? teardown_name
        $DEBUG and warn "Calling #{teardown_name}."
        __send__(bc_method.teardown_name)
      end
    end

    # General setup for all the benchmark methods.
    def setup
    end
    
    # General teardown for all the benchmark methods.
    def teardown
    end
  end

  # This module contains methods, that can be used in the evaluation method of
  # benchmark cases.
  module EvaluationModule
    def statistics_table(clock)
      result = ' ' * NAME_COLUMN_SIZE << ('%17s ' * 4) % times << "\n"
      result << evaluation_line('sum', times.map { |t| clock.__send__(t) })
      result << evaluation_line('min', times.map { |t| clock.min(t) })
      result << evaluation_line('std-', times.map { |t| clock.arithmetic_mean(t) - clock.sample_standard_deviation(t) })
      result << evaluation_line('mean', times.map { |t| clock.arithmetic_mean(t) })
      result << evaluation_line('std+', times.map { |t| clock.arithmetic_mean(t) + clock.sample_standard_deviation(t) })
      result << evaluation_line('max', times.map { |t| clock.max(t) })
      result << evaluation_line('std', times.map { |t| clock.sample_standard_deviation(t) })
      result << evaluation_line('std%', times.map { |t| clock.sample_standard_deviation_percentage(t) })
      result << evaluation_line('harm', times.map { |t| clock.harmonic_mean(t) })
      result << evaluation_line('geo', times.map { |t| clock.geometric_mean(t) })
      result << evaluation_line('q1', times.map { |t| clock.percentile(t, 25) })
      result << evaluation_line('med', times.map { |t| clock.median(t) })
      result << evaluation_line('q3', times.map { |t| clock.percentile(t, 75) })
      result << ' ' * NAME_COLUMN_SIZE << "%17u %17.5f %17.9f\n" % [ clock.repeat, clock.calls_mean, clock.call_time_mean ]
      result << ' ' * NAME_COLUMN_SIZE << "%17s %17s %17s\n" % %w[calls calls/sec secs/call]
    end

    def histogram(clock)
      result = "\n"
      if clock.case.histogram.enabled
        clock.histogram(clock.case.compare_time).display(result, 50)
      end
      result
    end

    def detect_outliers(clock)
      result = ''
      if clock.case.detect_outliers and
        outliers = clock.detect_outliers(clock.case.compare_time)
      then
        result << "\nOutliers detected with box plot algo "\
          "(median=%.5f, iqr=%.5f, factor=%.2f):\n" % outliers.values_at(:median, :iqr, :factor)
        result << outliers.select { |n, |
          [ :very_low, :low, :high, :very_high ].include?(n)
        }.map { |n, v| "#{n}=#{v}" } * ' '
        result << "\n"
      else
        result << "\nNo outliers detected with box plot algo.\n"
      end
      result
    end

    def detect_autocorrelation(clock)
      result = ''
      clock.case.autocorrelation.enabled or return result
      if r = clock.detect_autocorrelation(clock.case.compare_time)
        result << "\nLjung-Box statistics: q=%.5f (alpha=#{r[:alpha_level]},"\
          " df=#{r[:lags]}).\n" % r[:q]
        if r[:detected]
          result << "%.5f >= %.5f => Autocorrelation was detected.\n" %
            [ r[:p], 1 - r[:alpha_level] ]
        else
          result << "%.5f < %.5f => No autocorrelation was detected.\n" %
            [ r[:p], 1 - r[:alpha_level] ]
        end
      else
          result << "\nDidn't have enough lags to compute Ljung-Box statistics.\n"
      end
      result
    end

    private

    def evaluation_line(name, values)
      name.ljust(NAME_COLUMN_SIZE) << ('%17.9f ' * 4) % values << "\n"
    end

    def times
      self.class.clock.times
    end
  end

  # This is a Benchmarking Case that uses a time limit.
  class TimeCase < Case
    include EvaluationModule

    class << self
      extend DSLKit::DSLAccessor
      extend DSLKit::Constant

      constant :clock_method, :time

      dsl_accessor :duration

      dsl_accessor :run_count, 0

      def message
        "Running '#{self}' for a duration of #{duration} secs/method"\
          " (compare_time=#{compare_time}):"
      end

      dsl_accessor(:output) { ::Bullshit::Case.output }
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

  # This is a Benchmarking Case that uses a repetition limit.
  class RepeatCase < Case
    include EvaluationModule

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

      dsl_accessor(:output) { ::Bullshit::Case.output }
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

  # A range case is a benchmark case, where each iteration depends on a
  # different argument, which might cause a non-constant running time. The
  # evaluation of the case doesn't check for constancy and steady-state
  # properties.
  class RangeCase < Case
    include EvaluationModule

    class << self
      extend DSLKit::DSLAccessor
      extend DSLKit::Constant

      constant :clock_method, :scale_range

      dsl_accessor :range

      dsl_accessor :scatter, 1

      dsl_accessor :run_count, 0

      def message
        "Running '#{self}' for range #{range.inspect}"\
          " (compare_time=#{compare_time})"
      end

      dsl_accessor(:output) { ::Bullshit::Case.output }

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

  # A Comparison instance compares the benchmark results of different
  # case methods and outputs the results.
  class Comparison
    extend DSLKit::Constant
    extend DSLKit::DSLAccessor

    include CommonConstants

    dsl_accessor :output, STDOUT

    dsl_accessor :output_dir, Dir.pwd

    # Output results to the file named +name+.
    def output_filename(name)
      path = File.expand_path(name, output_dir)
      output File.new(path, 'a+')
    end

    # Return a comparison object configured by +block+.
    def initialize(&block)
      @cases = {}
      @benchmark_methods = []
      block and instance_eval(&block)
    end 

    # Benchmark case method +method+ of +bc_class+. Options are:
    # * :run to not run this +bc_class+ if set to false (defaults to true),
    # * :load to load the data of a previous run for this +method+, if set to
    #   true. If the true value is a file path string, load the data from the
    #   given file at the path.
    def benchmark(bc_class, method, opts = {})
      opts = { :run => true, :combine => true }.merge opts
      if Case === bc_class
        bullshit_case, bc_class = bc_class, bullshit_case.class
        @cases[bc_class] ||= []
        if opts[:combine]
          if @cases[bc_class].empty?
            @cases[bc_class] << bullshit_case
          else
            bullshit_case = @cases[bc_class].first
          end
        else
          @cases[bc_class] << bullshit_case
        end
      else
        @cases[bc_class] ||= []
        if opts[:combine]
          unless bullshit_case = @cases[bc_class].first
            bullshit_case = bc_class.new
            @cases[bc_class] << bullshit_case
          end
        else
          bullshit_case = bc_class.new
          @cases[bc_class] << bullshit_case
        end
      end
      bc_method = bullshit_case[method] or raise BullshitException,
        "unknown benchmark method #{bc_class}##{method}"
      if comment = opts[:comment]
        bc_method.comment = comment
      end
      if file_path = opts[:load]
        success = if file_path != true
          bc_method.load(file_path)
        else
          bc_method.load
        end
        if success
          @benchmark_methods << bc_method
        else
          warn "Loading of #{bc_method} failed. Skipping to next."
        end
      else
        opts[:run] and bullshit_case.run false
      end
      nil
    end

    # Return all benchmark methods for all the cached benchmark cases.
    attr_reader :benchmark_methods

    # Return all benchmark methods ordered by the result of comparator call to
    # their clock values.
    def compare_methods(comparator)
      benchmark_methods.sort_by { |m| m.clock.__send__(comparator) }
    end

    # Return the length of the longest name of all benchmark methods.
    def longest_name_size
      benchmark_methods.map { |m| m.long_name.size }.max
    end

    # Returns the prefix_string for a method speed comparison in the output.
    def prefix_string(method)
      "% -#{longest_name_size}s %u repeats:" %
        [ method.long_name , method.clock.repeat ]
    end

    # Output all speed comparisons between methods.
    def display
      output.puts Time.now.strftime(' %FT%T %Z ').center(COLUMNS, '=')
      for comparator in [ :call_time_mean, :call_time_median ]
        output.puts
        cmethods = compare_methods(comparator)
        cmethods.size < 2 and return
        max = cmethods.last.clock.__send__(comparator)
        output.puts "Comparing times (#{comparator}):"
        cmethods.each_with_index do |m, i|
          output.printf\
            "% 2u #{prefix_string(m)}\n   %17.9f"\
            " (%#{::Bullshit::Clock::TIMES_MAX}s) %s\n"\
            "   %17.9f %8.2f\n",
            i + 1, m.clock.calls(comparator), m.case.class.compare_time,
            compute_covers(cmethods, m), m.clock.__send__(comparator),
            m.clock.sample_standard_deviation_percentage(m.case.class.compare_time)
        end
        output.puts "   %17s (%#{::Bullshit::Clock::TIMES_MAX}s) %s\n"\
                    "   %17s %8s\n"\
                    % %w[calls/sec time covers secs/call std%]
        display_speedup_matrix(cmethods, comparator)
      end
      output.puts '=' * COLUMNS
    end

    private

    def display_speedup_matrix(cmethods, comparator)
      output.print "\n", " " * 3
      cmethods.size.times do |i|
        output.printf "%7d ", i + 1
      end
      output.puts
      cmethods.each_with_index do |x, i|
        output.printf "%2d ", i + 1
        cmethods.each do |y|
          ratio = x.clock.calls(comparator).to_f / y.clock.calls(comparator)
          ratio /= 0.0 if ratio >= 1000
          output.printf "%7.2f ", ratio
        end
        output.puts
      end
    end

    def compute_covers(cmethods, m)
      covers = []
      for x in cmethods
        if m != x and m.cover?(x)
          j = 0
          if cmethods.find { |y| j += 1; x == y }
            my_case = m.case.class
            iterations = m.clock.analysis[my_case.compare_time].suggested_sample_size(
              x.clock.analysis[my_case.compare_time], my_case.covering.alpha_level, my_case.covering.beta_level)
            if iterations.nan? or iterations.infinite?
              covers << "#{j} (?)"
            else
              min_iterations = iterations.ceil
              min_iterations >= 1E6 and min_iterations = "%f" % (1 / 0.0)
              covers << "#{j} (>=#{min_iterations})"
            end
          end
        end
      end
      covers * ', '
    end
  end

  # Create a Comparison instance configured by +block+ and compute and display
  # the results.
  def self.compare(&block)
    Comparison.new(&block).display
  end

  at_exit do
    Case.autorun and Case.run_all
  end
end
