require 'carnivore/utils'
require 'carnivore/callback'
require 'carnivore/message'

module Carnivore
  class Source

    class << self
    end

    class SourceContainer

      attr_reader :klass
      attr_reader :source_hash

      # class_name:: Name of source class
      # args:: argument hash to pass to source instance
      def initialize(class_name, args={})
        @klass = class_name
        @source_hash = args || {}
        @source_hash[:callbacks] = {}
      end

      # name:: Name of callback
      # klass:: Class of callback (optional)
      # Add a callback to a source via Class or block
      def add_callback(name, klass=nil, &block)
        @source_hash[:callbacks][name] = klass || block
      end
    end

    class << self

      # args:: Hash
      #  :type -> Source type
      #  :args -> arguments for `Source` instance
      # Builds a source container of `:type`
      def build(args={})
        [:args, :type].each do |key|
          unless(args.has_key?(key))
            raise ArgumentError.new "Missing required parameter `:#{key}`"
          end
        end
        require Source.require_path(args[:type]) || "carnivore/source/#{args[:type]}"
        klass = args[:type].to_s.split('_').map(&:capitalize).join
        klass = Source.const_get(klass)
        args[:args][:name] ||= Celluloid.uuid
        inst = SourceContainer.new(klass, args[:args])
        register(inst)
        inst
      end


      def provide(type, require_path)
        @source_klass ||= {}
        @source_klass[type.to_sym] = require_path
        true
      end

      def require_path(type)
        @source_klass ||= {}
        @source_klass[type.to_sym]
      end

      # inst: SourceContainer
      # Register the container
      def register(inst)
        @sources ||= []
        @sources << inst
        true
      end

      # Registered containers
      def sources
        @sources || []
      end
    end

    include Celluloid
    include Utils::Logging

    attr_reader :name
    attr_reader :callbacks
    attr_reader :auto_confirm
    attr_reader :auto_process
    attr_reader :callback_supervisor

    def initialize(args={})
      @callbacks = []
      @callback_names = {}
      @auto_process = true
      @callback_supervisor = Celluloid::SupervisionGroup.run!
      @name = args[:name] || Celluloid.uuid
      @auto_confirm = !!args[:auto_confirm]
      if(args[:callbacks])
        args[:callbacks].each do |name, block|
          add_callback(name, block)
        end
      end
      setup(args)
      connect
      async.process if @auto_process
    rescue => e
      debug "Failed to initialize: #{self} - #{e.class}: #{e}\n#{e.backtrace.join("\n")}"
      raise
    end

    def auto_confirm?
      @auto_confirm
    end

    def inspect
      "<#{self.class.name}:#{object_id} @name=#{name} @callbacks=#{Hash[*callbacks.map{|k,v| [k,v.object_id]}.flatten]}>"
    end

    def to_s
      "<#{self.class.name}:#{object_id} @name=#{name}>"
    end

    def setup(args={})
      debug 'No custom setup declared'
    end

    def connect(args={})
      debug 'No custom connect declared'
    end

    def receive(n=1)
      raise NoMethodError.new('Abstract method not valid for runtime')
    end

    def transmit(message)
      raise NoMethodError.new('Abstract method not valid for runtime')
    end

    def terminate
      if(@callback_supervisor)
        @callback_supervisor.actors.map(&:terminate)
      end
    end

    def add_callback(name, block_or_class)
      if(block_or_class.is_a?(Class))
        size = block_or_class.workers || 1
        if(size < 1)
          warn "Callback class (#{block_or_class}) defined no workers. Skipping."
          return self
        elsif(size == 1)
          debug "Adding callback class (#{block_or_class}) under supervision. Name: #{callback_name(name)}"
          @callback_supervisor.supervise_as callback_name(name), block_or_class, name
        else
          debug "Adding callback class (#{block_or_class}) under supervision pool (#{size} workers). Name: #{callback_name(name)}"
          @callback_supervisor.pool block_or_class, as: callback_name(name), size: size, args: [name]
        end
      else
        debug "Adding custom callback class  from block (#{block_or_class}) under supervision. Name: #{callback_name(name)}"
        @callback_supervisor.supervise_as callback_name(name), Callback, name, block_or_class
      end
      @callbacks.push(name).uniq!
      self
    end

    def remove_callback(name)
      unless(@callbacks.include?(callback_name(name)))
        raise NameError.new("Failed to locate callback named: #{name}")
      end
      actors[callback_name(name)].terminate
      @callbacks.delete(name)
      self
    end

    def callback_name(name)
      unless(@callback_names[name])
        @callback_names[name] = [@name, self.object_id, name].join(':').to_sym
      end
      @callback_names[name]
    end

    def format(msg)
      Message.new(
        :message => msg,
        :source => self
      )
    end

    def process
      loop do
        msgs = Array(receive).flatten.compact.map do |m|
          format(m)
        end
        msgs.each do |msg|
          @callbacks.each do |name|
            debug "Dispatching message<#{msg[:message].object_id}> to callback<#{name} (#{callback_name(name)})>"
            Celluloid::Actor[callback_name(name)].async.call(msg)
          end
        end
      end
    end

  end
end
