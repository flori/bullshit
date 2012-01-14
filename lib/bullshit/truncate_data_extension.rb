require 'bullshit/block_configuration'

module Bullshit
  module TruncateDataExtension
    class TruncateData < BlockConfiguration
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
  end
end
