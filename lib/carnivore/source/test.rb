module Carnivore
  class Source
    class Test < Source

      RAND_MAX = 99999
      RAND_DIV = 3
      RAND_SLEEP = 10

      def setup(args={})
      end

      def connect(*args)
        info 'Test connect called'
      end

      def receive(*args)
        if(rand(RAND_MAX) % RAND_DIV == 0)
          sleep_for = rand(RAND_SLEEP)
          debug "Test source sleep for: #{sleep_for}"
          sleep sleep_for
        end
        20.times.map{('a'..'z').to_a.shuffle.first}.join
      end

      def transmit(message)
        info "Transmit requested: #{message}"
      end

    end
  end
end
