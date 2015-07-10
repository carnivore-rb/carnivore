require 'carnivore'

module Carnivore
  # Payload modifier
  class Callback

    class << self
      # Define number of workers to create
      attr_accessor :workers
    end

    include Celluloid
    include Carnivore::Utils::Logging
    # @!parse include Carnivore::Utils::Logging
    include Carnivore::Utils::Failure
    # @!parse include Carnivore::Utils::Failure

    # @return [String, Symbol] name of callback
    attr_reader :name
    # @return [Carnivore::Source] source this callback is attached
    attr_reader :source

    # Creates a new callback. Optional block to define callback
    # behavior must be passed as a `Proc` instance, not a block.
    #
    # @param name [String, Symbol] name of the callback
    # @param block [Proc] optionally define the callback behavior
    def initialize(name, source, block=nil)
      @name = name
      @source = source
      if(block.nil? && self.class == Callback)
        raise ArgumentError.new 'Block is required for dynamic callbacks!'
      end
      define_singleton_method(:execute, &block) if block
      execute_and_retry_forever(:setup) do
        setup
      end
    end

    # Used by custom callback classes for setup
    def setup
      debug 'No custom setup defined'
    end

    # Provide nice output when printed
    #
    # @return [String]
    def inspect
      "callback<#{self.name}:#{self.object_id}>"
    end
    alias_method :to_s, :inspect

    # Message is valid for this callback
    #
    # @param message [Carnivore::Message]
    # @return [TrueClass, FalseClass]
    def valid?(message)
      true
    end

    # Execute callback against given message
    #
    # @param message [Carnivore::Message]
    def call(message)
      begin
        if(valid?(message))
          info ">> Received message is valid for this callback (#{message})"
          execute(message)
        else
          debug "Invalid message for this callback #{message})"
        end
      rescue => e
        error "[callback: #{self}, source: #{message[:source]}, message: #{message}]: #{e.class} - #{e} (UNHANDLED ERROR)"
        debug "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
        nil
      end
    end

  end
end
