module Bullshit
  module OutputExtension
    class Output
      extend DSLKit::Constant
      extend DSLKit::DSLAccessor

      def initialize(&block)
        block and instance_eval(&block)
      end

      dsl_accessor :file, STDOUT

      dsl_accessor :dir, Dir.pwd

      def filename(name)
        path = File.expand_path(name, dir)
        file File.new(path, 'a+')
      end
    end

    def output(file = nil, &block)
      @output ||= Output.new(&block)
      if file.nil? and !block
        @output
      else
        file and @output.file file
      end
    end
  end
end
