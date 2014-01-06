require 'carnivore/autoloader'

module Carnivore
  class << self

    # block:: Block of configuration
    # Add configuration to Carnivore
    def configure(&block)
      mod = Container.new
      mod.instance_exec(mod, &block)
      self
    end

    # Start carnivore
    def start!
      supervisor = nil
      begin
        require 'carnivore/supervisor'
        supervisor = Carnivore::Supervisor.build!
        Source.sources.each do |source|
          source.klass.reset_comms!
          supervisor.supervise_as(
            source.source_hash[:name],
            source.klass,
            source.source_hash.dup
          )
        end
        loop do
          # We do a sleep loop so we can periodically check on the
          # supervisor and ensure it is still alive. If it has died,
          # raise exception to allow cleanup and restart attempt
          sleep Carnivore::Config.get(:carnivore, :supervisor, :poll) || 5 while supervisor.alive?
          Celluloid::Logger.error 'Carnivore supervisor has died!'
          raise Carnivore::Error::DeadSupervisor.new
        end
      rescue Carnivore::Error::DeadSupervisor
        Celluloid::Logger.warn "Received dead supervisor exception. Attempting to restart."
        begin
          supervisor.terminate
        rescue => e
          Celluloid::Logger.debug "Exception raised during supervisor termination (restart cleanup): #{e}"
        end
        Celluloid::Logger.debug "Pausing restart for 10 seconds to prevent restart thrashing cycles"
        sleep 10
        retry
      rescue Exception => e
        supervisor.terminate
        # Gracefully shut down
      end
    end
  end
end
