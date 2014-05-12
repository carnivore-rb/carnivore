module Carnivore
  class Source
    # Test source
    class Test < Source

      # Maximum rand value
      RAND_MAX = 99999
      # Default rand divisor
      RAND_DIV = 3
      # Sleep length when valid
      RAND_SLEEP = 10

      # Note that we are connected
      def connect(*args)
        info 'Test connect called'
      end

      # Receive randomly generated message
      #
      # @return [Array<String>]
      def receive(*args)
        if(rand(RAND_MAX) % RAND_DIV == 0)
          sleep_for = rand(RAND_SLEEP)
          debug "Test source sleep for: #{sleep_for}"
          sleep sleep_for
        end
        20.times.map{('a'..'z').to_a.shuffle.first}.join
      end

      # Dummy transmit message
      #
      # @param message [Carnivore::Message]
      def transmit(message)
        info "Transmit requested: #{message}"
      end

    end
  end
end
