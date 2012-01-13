require 'bullshit/output_extension'

module Bullshit
  # A Comparison instance compares the benchmark results of different
  # case methods and outputs the results.
  class Comparison
    extend DSLKit::Constant
    extend DSLKit::DSLAccessor

    include CommonConstants
    include OutputExtension

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
      output.file.puts Time.now.strftime(' %FT%T %Z ').center(COLUMNS, '=')
      for comparator in [ :call_time_mean, :call_time_median ]
        output.file.puts
        cmethods = compare_methods(comparator)
        cmethods.size < 2 and return
        output.file.puts "Comparing times (#{comparator}):"
        cmethods.each_with_index do |m, i|
          output.file.printf\
            "% 2u #{prefix_string(m)}\n   %17.9f"\
            " (%#{::Bullshit::Clock::TIMES_MAX}s) %s\n"\
            "   %17.9f %8.2f %17.9f\n",
            i + 1, m.clock.calls(comparator), m.case.class.compare_time,
            compute_covers(cmethods, m), m.clock.__send__(comparator),
            m.clock.sample_standard_deviation_percentage(m.case.class.compare_time),
            m.clock.sum(m.case.class.compare_time)
        end
        output.file.puts "   %17s (%#{::Bullshit::Clock::TIMES_MAX}s) %s\n"\
                    "   %17s %8s %17s\n"\
                    % %w[calls/sec time covers secs/call std% sum]
        display_speedup_matrix(cmethods, comparator)
      end
      output.file.puts '=' * COLUMNS
    end

    private

    def display_speedup_matrix(cmethods, comparator)
      output.file.print "\n", " " * 3
      cmethods.size.times do |i|
        output.file.printf "%7d ", i + 1
      end
      output.file.puts
      cmethods.each_with_index do |x, i|
        output.file.printf "%2d ", i + 1
        cmethods.each do |y|
          ratio = x.clock.calls(comparator).to_f / y.clock.calls(comparator)
          ratio /= 0.0 if ratio >= 1000
          output.file.printf "%7.2f ", ratio
        end
        output.file.puts
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
end
