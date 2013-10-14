require 'carnivore/source'

module Carnivore
  class Message

    attr_reader :args

    def initialize(args={})
      unless(args[:source])
        raise ArgumentError.new("A valid `Carnivore::Source` must be provided via `:source`")
      end
      @args = args.dup
    end

    def [](k)
      @args[k.to_sym] || @args[k.to_s]
    end

    def confirm!
      self[:source].confirm(self)
    end

    def inspect
      "<Carnivore::Message[#{self.object_id}] @args=#{args}>"
    end

    def to_s
      "<Carnivore::Message:#{self.object_id}>"
    end
  end
end
