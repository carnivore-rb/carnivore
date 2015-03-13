require 'digest/sha2'
require 'carnivore'

module Carnivore
  # Message source
  # @abstract
  class Source

    autoload :SourceContainer, 'carnivore/source_container'

    class << self

      include Bogo::Memoization

      # Builds a source container
      #
      # @param args [Hash] source configuration
      # @option args [String, Symbol] :type type of source to build
      # @option args [Hash] :args configuration hash for source initialization
      # @return [SourceContainer]
      def build(args={})
        [:args, :type].each do |key|
          unless(args.has_key?(key))
            abort ArgumentError.new "Missing required parameter `:#{key}`"
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

      # @return [Smash] Source class information
      def source_classes
        memoize(:source_classes, :global) do
          Smash.new
        end
      end

      # @return [Smash] Registered source information
      def sources_registry
        memoize(:sources, :global) do
          Smash.new
        end
      end

      # Register a new source type
      #
      # @param type [Symbol] name of source type
      # @param require_path [String] path to require when requested
      # @return [TrueClass]
      def provide(type, require_path)
        source_classes[type] = require_path
        true
      end

      # Registered path for given source type
      #
      # @param type [String, Symbol] name of source type
      # @return [String, NilClass]
      def require_path(type)
        source_classes[type]
      end

      # Register the container
      #
      # @param name [String, Symbol] name of source
      # @param inst [SourceContainer]
      # @return [TrueClass]
      def register(name, inst)
        sources_registry[name] = inst
        true
      end

      # Source container with given name
      #
      # @param name [String, Symbol] name of source
      # @return [SourceContainer]
      def source(name)
        if(sources_registry[name])
          sources_registry[name]
        else
          Celluloid.logger.error "Source lookup failed (name: #{name})"
          abort KeyError.new("Requested named source is not registered: #{name}")
        end
      end

      # @return [Array<SourceContainer>] registered source containers
      def sources
        sources_registry.values
      end

      # @return [NilClass] Remove any registered sources
      def clear!
        sources_registry.clear
      end

      # Reset communication methods within class
      def reset_comms!
        self.class_eval do
          unless(method_defined?(:reset_communications?))
            alias_method :custom_transmit, :transmit
            alias_method :transmit, :_transmit
            def reset_communications?
              true
            end
          end
        end
      end

    end

    include Celluloid
    include Utils::Logging
    # @!parse include Carnivore::Utils::Logging
    include Utils::Failure
    # @!parse include Carnivore::Utils::Failure

    finalizer :teardown_cleanup

    # @return [String, Symbol] name of source
    attr_reader :name
    # @return [Array<Callback>] registered callbacks
    attr_reader :callbacks
    # @return [TrueClass, FalseClass] auto confirm received messages
    attr_reader :auto_confirm
    # @return [TrueClass, FalseClass] start source processing on initialization
    attr_reader :auto_process
    # @return [TrueClass, FalseClass] message processing control switch
    attr_reader :run_process
    # @return [Carnivore::Supervisor] supervisor maintaining callback instances
    attr_reader :callback_supervisor
    # @return [Hash] registry of processed messages
    attr_reader :message_registry
    # @return [Queue] local loop message queue
    attr_reader :message_loop
    # @return [Queue] remote message queue
    attr_reader :message_remote
    # @return [TrueClass, FalseClass] currently processing a message
    attr_reader :processing
    # @return [TrueClass, FalseClass] allow multiple callback matches
    attr_reader :allow_multiple_matches
    # @return [Hash] original options hash
    attr_reader :arguments

    # @note this is just a compat method for older sources
    alias_method :args, :arguments

    # Create new Source
    #
    # @param args [Hash]
    # @option args [String, Symbol] :name name of source
    # @option args [TrueClass, FalseClass] :auto_process start processing on initialization
    # @option args [TrueClass, FalseClass] :auto_confirm confirm messages automatically on receive
    # @option args [Proc] :orphan_callback execute block when no callbacks are valid for message
    # @option args [Proc] :multiple_callback execute block when multiple callbacks are valid and multiple support is disabled
    # @option args [TrueClass, FalseClass] :prevent_duplicates setup and use message registry
    # @option args [TrueClass, FalseClass] :allow_multiple_matches allow multiple callback matches (defaults true)
    # @option args [Array<Callback>] :callbacks callbacks to register on this source
    def initialize(args={})
      @arguments = args.dup
      @name = args[:name]
      @args = Smash.new(args)
      @callbacks = []
      @message_loop = Queue.new
      @message_remote = Queue.new
      @callback_names = {}
      @auto_process = !!args.fetch(:auto_process, true)
      @run_process = true
      @auto_confirm = !!args[:auto_confirm]
      @callback_supervisor = Carnivore::Supervisor.create!.last
      @allow_multiple_matches = !!args.fetch(:allow_multiple_matches, true)
      [:orphan_callback, :multiple_callback].each do |key|
        if(args[key])
          unless(args[key].is_a?(Proc))
            raise TypeError.new("Expected `Proc` type for `#{key}` but received `#{args[key].class}`")
          end
          define_singleton_method(key, &args[key])
        end
      end
      if(args[:prevent_duplicates])
        init_registry
      end
      @processing = false
      @name = args[:name] || Celluloid.uuid
      if(args[:callbacks])
        args[:callbacks].each do |name, block|
          add_callback(name, block)
        end
      end
      execute_and_retry_forever(:setup) do
        setup(args)
      end
      execute_and_retry_forever(:connect) do
        connect
      end
      info 'Source initialization is complete'
    rescue => e
      debug "Failed to initialize: #{self} - #{e.class}: #{e}\n#{e.backtrace.join("\n")}"
      raise
    end

    # Start source if auto_process is enabled
    #
    # @return [TrueClass, FalseClass]
    def start!
      if(auto_process?)
        info 'Message processing started via auto start'
        async.process
        true
      else
        warn 'Message processing is disabled via auto start'
        false
      end
    end

    # @return [TrueClass, FalseClass] auto processing enabled
    def auto_process?
      auto_process && !callbacks.empty?
    end

    # Ensure we cleanup our internal supervisor before bailing out
    def teardown_cleanup
      warn 'Termination request received. Tearing down!'
      if(callback_supervisor && callback_supervisor.alive?)
        begin
          warn "Tearing down callback supervisor! (#{callback_supervisor})"
          callback_supervisor.terminate
        rescue Celluloid::Task::TerminatedError
          warn 'Terminated task error during callback supervisor teardown. Moving on.'
        end
      else
        warn 'Callback supervisor is not alive. No teardown issued'
      end
    end

    # @return [TrueClass, FalseClass] automatic message confirmation enabled
    def auto_confirm?
      @auto_confirm
    end

    # @return [String] inspection formatted string
    def inspect
      "<#{self.class.name}:#{object_id} @name=#{name} @callbacks=#{Hash[*callbacks.map{|k,v| [k,v.object_id]}.flatten]}>"
    end

    # @return [String] stringified instance
    def to_s
      "<#{self.class.name}:#{object_id} @name=#{name}>"
    end

    # Setup hook for source requiring customized setup
    #
    # @param args [Hash] initialization hash
    def setup(args={})
      debug 'No custom setup declared'
    end

    # Connection hook for sources requiring customized connect
    #
    # @param args [Hash] initialization hash
    def connect
      debug 'No custom connect declared'
    end

    # Receive messages from source
    # @abstract
    #
    # @param n [Integer] number of messages
    # @return [Object, Array<Object>] payload or array of payloads
    def receive(n=1)
      raise NotImplementedError.new('Abstract method not valid for runtime')
    end

    # Send payload to source
    #
    # @param message [Object] payload
    # @param original_message [Carnviore::Message] original message if reply to extract optional metadata
    # @param args [Hash] optional extra arguments
    def transmit(message, original_message=nil, args={})
      raise NotImplemented.new('Abstract method not valid for runtime')
    end

    # Touch message to reset timeout
    #
    # @param message [Carnivore::Message]
    # @return [TrueClass, FalseClass]
    def touch(message)
      warn 'Source#touch was not implemented for this source!'
      true
    end

    # Confirm receipt of the message on source
    #
    # @param message [Carnivore::Message]
    def confirm(message)
      debug 'No custom confirm declared'
    end

    # Adds the given callback to the source for message processing
    #
    # @param callback_name [String, Symbol] name of callback
    # @param block_or_class [Carnivore::Callback, Proc]
    # @return [self]
    def add_callback(callback_name, block_or_class)
      name = "#{self.name}:#{callback_name}"
      if(block_or_class.is_a?(Class))
        size = block_or_class.workers || 1
        if(size < 1)
          warn "Callback class (#{block_or_class}) defined no workers. Skipping."
          return self
        elsif(size == 1)
          debug "Adding callback class (#{block_or_class}) under supervision. Name: #{callback_name(name)}"
          callback_supervisor.supervise_as callback_name(name), block_or_class, name, current_actor
        else
          debug "Adding callback class (#{block_or_class}) under supervision pool (#{size} workers). Name: #{callback_name(name)}"
          callback_supervisor.pool block_or_class, as: callback_name(name), size: size, args: [name, current_actor]
        end
      else
        debug "Adding custom callback class  from block (#{block_or_class}) under supervision. Name: #{callback_name(name)}"
        callback_supervisor.supervise_as callback_name(name), Callback, name, current_actor, block_or_class
      end
      callbacks.push(name).uniq!
      self
    end

    # Remove the named callback from the source
    #
    # @param name [String, Symbol]
    # @return [self]
    def remove_callback(name)
      unless(@callbacks.include?(callback_name(name)))
        abort NameError.new("Failed to locate callback named: #{name}")
      end
      actors[callback_name(name)].terminate
      @callbacks.delete(name)
      self
    end

    # Returns namespaced name (prefixed with source name and instance id)
    #
    # @param name [String, Symbol] name of callback
    # @return [Carnivore::Callback, NilClass]
    def callback_name(name)
      unless(@callback_names[name])
        @callback_names[name] = [@name, self.object_id, name].join(':').to_sym
      end
      @callback_names[name]
    end

    # Create new Message from received payload
    #
    # @param msg [Object] received payload
    # @return [Carnivore::Message]
    def format(msg)
      actor = Carnivore::Supervisor.supervisor[name]
      if(actor)
        if(msg.is_a?(Hash) && msg.keys.map(&:to_s).sort == ['content', 'raw'])
          Message.new(
            :message => msg[:raw],
            :content => msg[:content],
            :source => actor.current_actor
          )
        else
          Message.new(
            :message => msg,
            :source => actor.current_actor
          )
        end
      else
        abort "Failed to locate self in registry (#{name})"
      end
    end

    # Validate message is allowed before processing. This is currently
    # only used when the message registry is enabled to prevent
    # duplicate message processing.
    #
    # @param m [Carnivore::Message]
    # @return [TrueClass, FalseClass]
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

    # Process incoming messages from this source
    #
    # @param args [Object] list of arguments
    # @return [TrueClass]
    def process(*args)
      unless(processing)
        begin
          async.receive_messages
          @processing = true
          while(run_process && !callbacks.empty?)
            if(message_loop.empty? && message_remote.empty?)
              wait(:messages_available)
            end
            msgs = []
            msgs.push message_loop.pop unless message_loop.empty?
            msgs.push message_remote.pop unless message_remote.empty?
            msgs = [msgs].flatten.compact.map do |m|
              if(valid_message?(m))
                format(m)
              end
            end.compact
            msgs.each do |msg|
              if(multiple_callbacks? || respond_to?(:orphan_callback))
                valid_callbacks = callbacks.find_all do |name|
                  callback_supervisor[callback_name(name)].valid?(msg)
                end
              else
                valid_callbacks = callbacks
              end
              if(valid_callbacks.empty?)
                warn "Received message was not processed through any callbacks on this source: #{msg}"
                orphan_callback(msg) if respond_to?(:orphan_callback)
              elsif(valid_callbacks.size > 1 && !multiple_callbacks?)
                error "Received message is valid for multiple callbacks but multiple callbacks are disabled: #{msg}"
                multiple_callback(msg) if respond_to?(:multiple_callback)
              else
                valid_callbacks.each do |name|
                  debug "Dispatching message<#{msg[:message].object_id}> to callback<#{name} (#{callback_name(name)})>"
                  callback_supervisor[callback_name(name)].async.call(msg)
                end
              end
            end
          end
        ensure
          @processing = false
        end
        true
      else
        false
      end
    end

    # Receive messages from source
    # @return [TrueClass]
    def receive_messages
      loop do
        message_remote.push receive
        signal(:messages_available)
      end
      true
    end

    # Get received message on local loopback
    #
    # @param args [Object] argument list (unused)
    # @return [Carnivore::Message, NilClass]
    def loop_receive(*args)
      message_loop.shift
    end

    # Push message onto internal loop queue
    #
    # @param message [Carnivore::Message]
    # @param original_message [Object] unused
    # @param args [Hash] unused
    # @return [TrueClass]
    def loop_transmit(message, original_message=nil, args={})
      message_loop.push message
      signal(:messages_available)
      true
    end

    # Send to local loop if processing otherwise use regular transmit
    #
    # @param args [Object] argument list
    # @return [TrueClass, FalseClass]
    def _transmit(*args)
      begin
        if(loop_enabled? && processing)
          loop_transmit(*args)
        else
          custom_transmit(*args)
        end
        true
      rescue EncodingError => e
        error "Transmission failed due to encoding error! Error: #{e.class} - #{e} [(#{args.map(&:to_s).join(')(')})]"
        false
      end
    end

    # Local message loopback is enabled. Custom sources should
    # override this method to allow loopback delivery if desired
    #
    # @return [TrueClass, FalseClass]
    def loop_enabled?
      false
    end

    # Allow sending payload to multiple matching callbacks. Custom
    # sources should override this method to disable multiple
    # callback matches if desired.
    #
    # @return [TrueClass, FalseClass]
    def multiple_callbacks?
      allow_multiple_matches
    end

    # Load and initialize the message registry
    #
    # @return [MessageRegistry] new registry
    def init_registry
      require 'carnivore/message_registry'
      @message_registry = MessageRegistry.new
    end

  end
end
