module Carnivore
  module Utils

    # Registry used for preventing duplicate message processing
    class MessageRegistry

      include Zoidberg::Shell

      # Create new instance
      def initialize
        @store = []
        @size = 100
      end

      # Validity of message (not found within registry)
      #
      # @param message [Carnivore::Message]
      # @return [TrueClass, FalseClass]
      def valid?(message)
        checksum = sha(message)
        found = @store.include?(checksum)
        unless(found)
          push(checksum)
        end
        !found
      end

      # Register checksum into registry
      #
      # @param item [String] checksum
      # @return [self]
      def push(item)
        @store.push(item)
        if(@store.size > @size)
          @store.shift
        end
        self
      end

      # Generate checksum for given item
      #
      # @param thing [Object]
      # @return [String] checksum
      def sha(thing)
        unless(thing.is_a?(String))
          thing = MultiJson.dump(thing)
        end
        (Digest::SHA512.new << thing).hexdigest
      end
    end
  end
end
