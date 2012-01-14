require 'dslkit'
class Object; include DSLKit::Eigenclass; end
require 'enumerator'
require 'more_math'

require 'bullshit/common_constants'
require 'bullshit/module_functions'
require 'bullshit/clock'
require 'bullshit/case_method'
require 'bullshit/comparison'
require 'bullshit/range_case'
require 'bullshit/repeat_case'
require 'bullshit/time_case'
require 'bullshit/version'

# Module that includes all constants of the bullshit library.
module Bullshit
  COLUMNS = 79            # Number of columns in the output.

  NAME_COLUMN_SIZE = 5    # Number of columns used for row names.

  RUBY_DESCRIPTION = "ruby %s (%s patchlevel %s) [%s]" %
    [ RUBY_VERSION, RUBY_RELEASE_DATE, RUBY_PATCHLEVEL, RUBY_PLATFORM ]

  # An excpeption raised by the bullshit library.
  class BullshitException < StandardError; end

  include MoreMath

  # Create a Comparison instance configured by +block+ and compute and display
  # the results.
  def self.compare(&block)
    Comparison.new(&block).display
  end

  at_exit do
    Case.autorun and Case.run_all
  end
end
