module Carnivore
  module Utils
      # Registry used for preventing duplicate message processing
    class MessageRegistry
      def initialize
        @store = []
        @size = 100
      end

      # message:: Carnivore::Message
      # Returns true if message has not been processed
      def valid?(message)
        checksum = sha(message)
        found = @store.include?(checksum)
        unless(found)
          push(checksum)
        end
        !found
      end

      # item:: checksum
      # Pushes checksum into store
      def push(item)
        @store.push(item)
        if(@store.size > @size)
          @store.shift
        end
        self
      end

      # thing:: Instance
      # Return checksum for give instance
      def sha(thing)
        unless(thing.is_a?(String))
          thing = MultiJson.dump(thing)
        end
        (Digest::SHA512.new << thing).hexdigest
      end
    end
  end
end
