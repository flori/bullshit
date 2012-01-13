module Bullshit
  module HistogramExtension
    class Histogram < BaseExtension
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
  end
end
