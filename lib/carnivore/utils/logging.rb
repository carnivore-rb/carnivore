require 'carnivore'

module Carnivore
  module Utils

    # Logging utilities
    module Logging

      # Define base logging types
      %w(debug info warn error).each do |key|
        define_method(key) do |string|
          log(key, string)
        end
      end

      # Log message
      #
      # @param args [Object] argument list
      # @return [NilClass]
      def log(*args)
        if(args.empty?)
          Celluloid::Logger
        else
          severity, string = args
          Celluloid::Logger.send(severity.to_sym, "#{self}: #{string}")
        end
      end

      # Log exception
      #
      # @param e [Exception]
      def exception_log(e)
        error "#{e.class}: #{e}"
        debug "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
      end

    end

  end
end
