module Bullshit
  class DetectOutliers < BaseExtension
    dsl_accessor :enabled, true

    dsl_accessor :factor, 3.0

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

  module DetectOutliersExtension
    def detect_outliers(enable = nil, &block)
      @detect_outliers ||= DetectOutliers.new(enable, &block)
    end
  end
end
