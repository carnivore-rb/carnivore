require 'celluloid'
require 'carnivore/config'
require 'carnivore/source'
require 'carnivore/container'
require 'carnivore/errors'

module Carnivore
  class << self
    def configure(&block)
      mod = Container.new
      mod.instance_exec(mod, &block)
      self
    end

    def start!
      supervisor = nil
      begin
        require 'carnivore/supervisor'
        supervisor = Carnivore::Supervisor.build!
        Source.sources.each do |source|
          supervisor.supervise_as(
            source.source_hash[:name],
            source.klass,
            source.source_hash.dup
          )
        end
        loop do
          sleep 5 while supervisor.alive?
          Celluloid::Logger.error 'Carnivore supervisor has died!'
          raise Carnivore::Error::DeadSupervisor.new
        end
      rescue Carnivore::Error::DeadSupervisor
        warn "Received dead supervisor exception. Attempting to restart."
        begin
          supervisor.terminate
        rescue => e
          debug "Exception raised during supervisor termination (restart cleanup): #{e}"
        end
        retry
      rescue Exception => e
        supervisor.terminate
        # Gracefully shut down
      end
    end
  end
end
