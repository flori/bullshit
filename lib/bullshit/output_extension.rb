require 'bullshit/block_configuration'

module Bullshit
  module OutputExtension
    class Output < BlockConfiguration

      def initialize(&block)
        if block
          super(&block)
          instance_eval(&block)
        end
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
