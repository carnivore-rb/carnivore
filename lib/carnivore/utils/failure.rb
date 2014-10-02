require 'carnivore'

module Carnivore
  module Utils

    # Failure utilities
    module Failure

      # Attempt to execute provided block. If exception is raised, log
      # and pause before retry. Do this until success.
      #
      # @param action [String, Symbol] display name for block
      # @return [Object] result of yielded block
      def execute_and_retry_forever(action)
        begin
          debug "Starting #{action} process"
          result = yield
          debug "Completed #{action} process"
          result
        rescue => e
          error "#{action.to_s.capitalize} process encountered an error: #{e.class} - #{e}"
          debug "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          warn "Pausing for 5 seconds then retrying #{action}"
          sleep(5)
          retry
        end
      end

    end
  end
end
