module Bullshit
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
end
