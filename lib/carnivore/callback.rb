module Carnivore
  class Callback

    class << self
      attr_accessor :workers
    end

    include Celluloid
    include Celluloid::Logger

    execute_block_on_receiver :execute

    attr_reader :name

    def initialize(name, block=nil)
      @name = name
      @block = block
      if(@block.nil? && self.class == Callback)
        raise ArgumentError.new 'Block is required for dynamic callbacks!'
      end
      setup
    end

    def setup
    end

    def inspect
      "callback<#{self.object_id}>"
    end

    def call(message)
      @block ? execute(message, &@block) : execute(message)
    rescue => e
      error "[callback: #{self}, source: #{message[:source]}, message: #{message[:message].object_id}]: #{e.class} - #{e}"
      debug "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
    end

    def execute(message)
      yield message
    end

  end
end
