require 'digest/sha2'
require 'celluloid'
require 'carnivore/utils'
require 'carnivore/callback'
require 'carnivore/message'

module Carnivore
  class Source

    class MessageRegistry
      def initialize
        @store = []
        @size = 100
      end

      def valid?(message)
        checksum = sha(message)
        found = @store.include?(checksum)
        unless(found)
          push(checksum)
        end
        !found
      end

      def push(item)
        @store.push(item)
        if(@store.size > @size)
          @store.shift
        end
        self
      end

      def sha(thing)
        unless(thing.is_a?(String))
          thing = MultiJson.dump(thing)
        end
        (Digest::SHA512.new << thing).hexdigest
      end
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
        register(args[:args][:name], inst)
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

      # name:: Name of source
      # inst:: SourceContainer
      # Register the container
      def register(name, inst)
        @sources ||= {}
        @sources[name.to_sym] = inst
        true
      end

      # name:: Name of registered source
      # Return source container
      def source(name)
        if(@sources && @sources[name.to_sym])
          @sources[name.to_sym]
        else
          raise KeyError.new("Requested named source is not registered: #{name}")
        end
      end

      # Registered containers
      def sources
        @sources ? @sources.values : []
      end
    end

    include Celluloid
    include Utils::Logging

    attr_reader :name
    attr_reader :callbacks
    attr_reader :auto_confirm
    attr_reader :auto_process
    attr_reader :run_process
    attr_reader :callback_supervisor
    attr_reader :message_registry

    def initialize(args={})
      @callbacks = []
      @callback_names = {}
      @auto_process = args.fetch(:auto_process, true)
      @run_process = true
      @auto_confirm = !!args[:auto_confirm]
      @callback_supervisor = Celluloid::SupervisionGroup.run!
      @message_registry = MessageRegistry.new if args[:prevent_duplicates]
      @name = args[:name] || Celluloid.uuid
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

    def transmit(message, original_message, args={})
      raise NoMethodError.new('Abstract method not valid for runtime')
    end

    def confirm(message)
      debug 'No custom confirm declared'
    end

    def add_callback(callback_name, block_or_class)
      name = "#{self.name}:#{callback_name}"
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
      actor = Celluloid::Actor[name]
      if(actor)
        Message.new(
          :message => msg,
          :source => actor
        )
      else
        abort "Failed to locate self in registry (#{name})"
      end
    end

    def valid_message?(m)
      if(message_registry)
        if(message_registry.valid?(m))
          true
        else
          warn "Message was already received. Discarding: #{m.inspect}"
          false
        end
      else
        true
      end
    end

    def process(*args)
      while(run_process)
        msgs = Array(receive).flatten.compact.map do |m|
          if(valid_message?(m))
            format(m)
          end
        end.compact
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
