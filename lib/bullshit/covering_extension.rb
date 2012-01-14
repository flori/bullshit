require 'bullshit/block_configuration'

module Bullshit
  module CoveringExtension
    class Covering < BlockConfiguration
      dsl_accessor :alpha_level, 0.05

      dsl_accessor :beta_level, 0.05

      def initialize(&block)
        block and instance_eval(&block)
      end
    end

    def covering(&block)
      @covering = Covering.new(&block)
    end
  end
end
