require 'carnivore'

module Carnivore
  class Callback

    class << self
      # Define number of workers to create
      attr_accessor :workers
    end

    include Celluloid
    include Carnivore::Utils::Logging

    attr_reader :name, :source

    # name:: Name of the callback
    # block:: Optional `Proc` to define the callback behavior
    # Creates a new callback. Optional block to define callback
    # behavior must be passed as a `Proc` instance, not a block.
    def initialize(name, source, block=nil)
      @name = name
      @source = source
      if(block.nil? && self.class == Callback)
        raise ArgumentError.new 'Block is required for dynamic callbacks!'
      end
      define_singleton_method(:execute, &block) if block
      setup
    end

    # Used by custom callback classes for setup
    def setup
    end

    # Provide nice output when printed
    def inspect
      "callback<#{self.name}:#{self.object_id}>"
    end
    alias_method :to_s, :inspect

    # message:: Carnivore::Message
    # Return true if message should be handled by this callback
    def valid?(message)
      true
    end

    # message:: Carnivore::Message
    # Pass message to registered callbacks
    def call(message)
      if(valid?(message))
        debug ">> Received message is valid for this callback (#{message})"
        execute(message)
      else
        debug "Invalid message for this callback #{message})"
      end
    rescue => e
      error "[callback: #{self}, source: #{message[:source]}, message: #{message[:message].object_id}]: #{e.class} - #{e}"
      debug "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
    end

  end
end
