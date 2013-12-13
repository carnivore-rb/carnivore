require 'carnivore/source'

module Carnivore
  class Message

    attr_reader :args

    def initialize(args={})
      unless(args[:source])
        raise ArgumentError.new("A valid `Carnivore::Source` name must be provided via `:source`")
      end
      @args = args.dup
    end

    # k:: key
    # Accessor into message
    def [](k)
      @args[k.to_sym] || @args[k.to_s]
    end

    # args:: Arguments
    # Confirm message was received on source
    def confirm!(*args)
      self[:source].confirm(*([self] + args).flatten(1).compact)
    end

    # Formatted inspection string
    def inspect
      "<Carnivore::Message[#{self.object_id}] @args=#{args}>"
    end

    # String representation
    def to_s
      "<Carnivore::Message:#{self.object_id}>"
    end
  end
end
