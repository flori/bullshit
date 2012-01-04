module Bullshit
  # This module contains methods, that can be used in the evaluation method of
  # benchmark cases.
  module EvaluationModule
    def statistics_table(clock)
      result = ' ' * NAME_COLUMN_SIZE << ('%17s ' * 4) % times << "\n"
      result << evaluation_line('sum', times.map { |t| clock.sum(t) })
      result << evaluation_line('min', times.map { |t| clock.min(t) })
      result << evaluation_line('std-', times.map { |t| clock.arithmetic_mean(t) - clock.sample_standard_deviation(t) })
      result << evaluation_line('mean', times.map { |t| clock.arithmetic_mean(t) })
      result << evaluation_line('std+', times.map { |t| clock.arithmetic_mean(t) + clock.sample_standard_deviation(t) })
      result << evaluation_line('max', times.map { |t| clock.max(t) })
      result << evaluation_line('std', times.map { |t| clock.sample_standard_deviation(t) })
      result << evaluation_line('std%', times.map { |t| clock.sample_standard_deviation_percentage(t) })
      result << evaluation_line('harm', times.map { |t| clock.harmonic_mean(t) })
      result << evaluation_line('geo', times.map { |t| clock.geometric_mean(t) })
      result << evaluation_line('q1', times.map { |t| clock.percentile(t, 25) })
      result << evaluation_line('med', times.map { |t| clock.median(t) })
      result << evaluation_line('q3', times.map { |t| clock.percentile(t, 75) })
      result << ' ' * NAME_COLUMN_SIZE << "%17u %17.5f %17.9f\n" % [ clock.repeat, clock.calls_mean, clock.call_time_mean ]
      result << ' ' * NAME_COLUMN_SIZE << "%17s %17s %17s\n" % %w[calls calls/sec secs/call]
    end

    def histogram(clock)
      result = "\n"
      if clock.case.histogram.enabled
        clock.histogram(clock.case.compare_time).display(result, 50)
      end
      result
    end

    def detect_outliers(clock)
      result = ''
      if clock.case.detect_outliers and
        outliers = clock.detect_outliers(clock.case.compare_time)
      then
        result << "\nOutliers detected with box plot algo "\
          "(median=%.5f, iqr=%.5f, factor=%.2f):\n" % outliers.values_at(:median, :iqr, :factor)
        result << outliers.select { |n, |
          [ :very_low, :low, :high, :very_high ].include?(n)
        }.map { |n, v| "#{n}=#{v}" } * ' '
        result << "\n"
      else
        result << "\nNo outliers detected with box plot algo.\n"
      end
      result
    end

    def detect_autocorrelation(clock)
      result = ''
      clock.case.autocorrelation.enabled or return result
      if r = clock.detect_autocorrelation(clock.case.compare_time)
        result << "\nLjung-Box statistics: q=%.5f (alpha=#{r[:alpha_level]},"\
          " df=#{r[:lags]}).\n" % r[:q]
        if r[:detected]
          result << "%.5f >= %.5f => Autocorrelation was detected.\n" %
            [ r[:p], 1 - r[:alpha_level] ]
        else
          result << "%.5f < %.5f => No autocorrelation was detected.\n" %
            [ r[:p], 1 - r[:alpha_level] ]
        end
      else
          result << "\nDidn't have enough lags to compute Ljung-Box statistics.\n"
      end
      result
    end

    private

    def evaluation_line(name, values)
      name.ljust(NAME_COLUMN_SIZE) << ('%17.9f ' * 4) % values << "\n"
    end

    def times
      self.class.clock.times
    end
  end
end
