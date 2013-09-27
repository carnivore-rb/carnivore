require 'carnivore/utils'

module Carnivore
  class Callback

    class << self
      attr_accessor :workers
    end

    include Celluloid
    include Utils::Logging

    attr_reader :name

    def initialize(name, block=nil)
      @name = name
      if(block.nil? && self.class == Callback)
        raise ArgumentError.new 'Block is required for dynamic callbacks!'
      end
      define_singleton_method(:execute, &block) if block
      setup
    end

    def setup
    end

    def inspect
      "callback<#{self.name}:#{self.object_id}>"
    end

    def valid?(message)
      true
    end

    def call(message)
      if(valid?(message))
        execute(message)
      else
        debug 'Received message not valid for this callback'
      end
    rescue => e
      error "[callback: #{self}, source: #{message[:source]}, message: #{message[:message].object_id}]: #{e.class} - #{e}"
      debug "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
    end

  end
end
