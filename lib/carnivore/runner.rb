require 'carnivore'

module Carnivore
  class << self

    # Sets the global configuration
    #
    # @param path [String] configuration file or directory
    # @return [Bogo::Config]
    def configure!(*args)
      if(defined?(Carnivore::Config))
        if(!args.include?(:verify) && !args.include?(:force))
          raise 'Global configuration has already been set!'
        end
        if(args.include?(:force))
          Carnivore.send(:remove_const, :Config)
        end
      end
      unless(defined?(Carnivore::Config))
        Carnivore.const_set(:Config,
          Bogo::Config.new(
            args.first.is_a?(Symbol) ? Smash.new : args.first
          )
        )
      end
      Carnivore::Config
    end

    # Add configuration to Carnivore
    #
    # @yield block of configuration
    # @return [self]
    def configure(&block)
      mod = Container.new
      mod.instance_exec(mod, &block)
      self
    end

    # Start the Carnivore subsystem
    def start!
      supervisor = nil
      begin
        require 'carnivore/supervisor'
        configure!(:verify)
        supervisor = Carnivore::Supervisor.build!
        Carnivore::Logger.info 'Initializing all registered sources.'
        [].tap do |register|
          Source.sources.each do |source|
            register << Thread.new do
              supervisor.supervise_as(
                source.source_hash[:name],
                source.klass,
                source.source_hash.dup
              )
            end
          end
        end.map(&:join)
        Carnivore::Logger.info 'Source initializations complete. Running setup and establishing connections.'
        Source.sources.each do |source|
          supervisor[source.source_hash[:name]].run_setup
          supervisor[source.source_hash[:name]].run_connect
        end
        Carnivore::Logger.info 'Sources setup and connected. Enabling message processing.'
        Source.sources.each do |source|
          if(source.source_hash.fetch(:auto_process, true))
            supervisor[source.source_hash[:name]].start!
          end
        end
        loop do
          # We do a sleep loop so we can periodically check on the
          # supervisor and ensure it is still alive. If it has died,
          # raise exception to allow cleanup and restart attempt
          gc_interval = Carnivore::Config.fetch(:carnivore, :garbage_interval, 30)
          gc_last = Time.now.to_i
          while(supervisor.alive?)
            sleep Carnivore::Config.get(:carnivore, :supervisor, :poll) || 5
            if(gc_interval && (Time.now.to_i - gc_last) > gc_interval)
              Carnivore::Logger.debug 'Starting interval forced garbage collection from runner'
              GC.start
              gc_last = Time.now.to_i
            end
          end
          Carnivore::Logger.error 'Carnivore supervisor has died!'
          raise Carnivore::Error::DeadSupervisor.new
        end
      rescue Carnivore::Error::DeadSupervisor
        Carnivore::Logger.warn "Received dead supervisor exception. Attempting to restart."
        begin
          supervisor.terminate if supervisor.alive?
        rescue => e
          Carnivore::Logger.debug "Exception raised during supervisor termination (restart cleanup): #{e}"
        end
        Carnivore::Logger.debug "Pausing restart for 10 seconds to prevent restart thrashing cycles"
        sleep 10
        retry
      rescue Exception => e
        Carnivore::Logger.warn "Exception type encountered forcing shutdown - #{e.class}: #{e}"
        Carnivore::Logger.debug "Shutdown exception info: #{e.class}: #{e}\n#{e.backtrace.join("\n")}"
        supervisor.terminate if supervisor
        # Gracefully shut down
      end
    end
  end
end
