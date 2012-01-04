module Bullshit
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
end
