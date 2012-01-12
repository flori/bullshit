module Bullshit
  module AutocorrelationExtension
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
  end
end
