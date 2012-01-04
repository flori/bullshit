module Bullshit
  # This class' instance represents a method to be benchmarked.
  CaseMethod = Struct.new(:name, :case, :clock) do
    #
    # Return the short name of this CaseMethod instance, that is without the
    # "benchmark_" prefix, e. g. "foo".
    def short_name
      @short_name ||= name.sub(/\Abenchmark_/, '')
    end

    # The comment for this method.
    attr_accessor :comment

    # Returns the long_name of this CaseMethod of the form Foo#bar.
    def long_name
      result = "#{self.case}##{short_name}"
      result = "#{result} (#{comment})" if comment
      result
    end

    # Return the setup_name, e. g. "setup_foo".
    def setup_name
      'setup_' + short_name
    end

    # Return the before_name, e. g. "before_foo".
    def before_name
      'before_' + short_name
    end

    # Return the after_name, e. g. "after_foo".
    def after_name
      'after_' + short_name
    end

    # Return the teardown_name, e. g. "teardown_foo".
    def teardown_name
      'teardown_' + short_name
    end

    # Return true if this CaseMethod#clock covers other.clock.
    def cover?(other)
      clock.cover?(other.clock)
    end

    # Call before method of this CaseMethod before benchmarking it.
    def before_run
      if self.case.respond_to? before_name
        $DEBUG and warn "Calling #{before_name}."
        self.case.__send__(before_name)
      end
    end

    # Call after method of this CaseMethod after benchmarking it.
    def after_run
      if self.case.respond_to? after_name
        $DEBUG and warn "Calling #{after_name}."
        self.case.__send__(after_name)
      end
    end

    # Return the file name for +type+ with +suffix+ (if any) for this clock.
    def file_path(type = nil, suffix = '.dat')
      name = self.case.class.benchmark_name.dup
      name << '#' << short_name
      type and name << '-' << type
      name << suffix
      File.expand_path(name, self.case.class.output_dir)
    end

    # Load the data of file +fp+ into this clock.
    def load(fp = file_path)
      self.clock = self.case.class.clock.new self
      $DEBUG and warn "Loading '#{fp}' into clock."
      File.open(fp, 'r') do |f|
        f.each do |line|
          line.chomp!
          line =~ /^\s*#/ and next
          clock << line.split(/\t/)
        end
      end
      self
    rescue Errno::ENOENT
    end

    alias to_s long_name
  end
end
