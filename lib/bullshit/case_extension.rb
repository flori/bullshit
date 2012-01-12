require 'bullshit/covering_extension'
require 'bullshit/histogram_extension'
require 'bullshit/truncate_data_extension'
require 'bullshit/autocorrelation_extension'
require 'bullshit/detect_outliers_extension'

module Bullshit
  # All subclasses of Case are extended with this module.
  module CaseExtension
    def inherited(klass)
      Case.cases << klass
    end

    extend DSLKit::DSLAccessor
    extend DSLKit::Constant

    include CommonConstants
    include ModuleFunctions
    include CoveringExtension
    include HistogramExtension
    include TruncateDataExtension
    include AutocorrelationExtension
    include DetectOutliersExtension

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

    constant :aggressive, :aggressive

    dsl_accessor :data_file, false

    dsl_accessor :output_dir, Dir.pwd

    dsl_accessor :linear_regression, true
  end
end
