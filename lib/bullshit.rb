require 'dslkit'
require 'enumerator'

require 'bullshit/version'
require 'more_math'

# Module that includes all constants of the bullshit library.
module Bullshit
  COLUMNS = 79            # Number of columns in the output.

  NAME_COLUMN_SIZE = 5    # Number of columns used for row names.

  RUBY_DESCRIPTION = "ruby %s (%s patchlevel %s) [%s]" %
    [ RUBY_VERSION, RUBY_RELEASE_DATE, RUBY_PATCHLEVEL, RUBY_PLATFORM ]

  include MoreMath

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

      dsl_accessor :comparison, true

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
            enabled true
            instance_eval(&block)
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
            enabled true
            instance_eval(&block)
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
      if self.class.comparison
        @comparison = Comparison.new
        @comparison.output self.class.output
      end
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
        if @comparison
          @comparison.benchmark(self, bc_method.short_name, :run => false)
        end
      end
      @clocks
    end

    # The clock instances, that were used during a run of this benchmark case.
    attr_reader :clocks

    # Setup, run all benchmark cases (warmup and the real run) and output
    # results, run method speed comparisons, and teardown.
    def run(do_compare = true)
      old_sync, self.class.output.sync = self.class.output.sync, true
      $DEBUG and warn "Calling setup."
      setup
      run_once
      do_compare and @comparison and @comparison.display
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
    def self.run(do_compare = true)
      new.run do_compare
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
      result << evaluation_line('sum', times.map { |t| clock.sum(t) })
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
        bullshit_case, bc_class = bc_class, bc_class.class
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
        @benchmark_methods << bc_method
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
            "   %17.9f %8.2f %17.9f\n",
            i + 1, m.clock.calls(comparator), m.case.class.compare_time,
            compute_covers(cmethods, m), m.clock.__send__(comparator),
            m.clock.sample_standard_deviation_percentage(m.case.class.compare_time),
            m.clock.sum(m.case.class.compare_time)
        end
        output.puts "   %17s (%#{::Bullshit::Clock::TIMES_MAX}s) %s\n"\
                    "   %17s %8s %17s\n"\
                    % %w[calls/sec time covers secs/call std% sum]
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
