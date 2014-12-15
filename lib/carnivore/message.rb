require 'carnivore'

module Carnivore
  # Wraps a message (Hash) with Carnivore specific helpers
  class Message

    # @return [Hash] underlying message hash
    attr_reader :args

    # @param args [Hash]
    # @option args [Carnivore::Source] :source origin source of message
    def initialize(args={})
      args = args.to_smash
      unless(args[:source])
        raise ArgumentError.new("A valid `Carnivore::Source` name must be provided via `:source`")
      end
      @args = args
    end

    # @return [Array<String>] keys available in message hash
    def keys
      args.keys
    end

    # Message accessor
    #
    # @param k [String, Symbol]
    def [](k)
      args[k]
    end

    # Confirm message was received on source
    #
    # @param args [Object] list passed to Carnivore::Source#confirm
    def confirm!(*args)
      self[:source].confirm(*([self] + args).flatten(1).compact)
    end

    # Touch message on source
    #
    # @return [TrueClass, FalseClass]
    def touch!
      self[:source].touch(self)
    end

    # @return [String] formatted inspection string
    def inspect
      "<Carnivore::Message[#{self.object_id}] @args=#{args.inspect}>"
    end

    # @return [String] string representation
    def to_s
      "<Carnivore::Message:#{self.object_id}>"
    end
  end
end
