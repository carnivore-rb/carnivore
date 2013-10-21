require 'celluloid'
require 'carnivore/config'
require 'carnivore/source'
require 'carnivore/container'

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
        supervisor = Carnivore::Supervisor.run!
        Source.sources.each do |source|
          supervisor.supervise_as(
            source.source_hash[:name],
            source.klass,
            source.source_hash
          )
        end
        supervisor.wait(:kill_all_humans)
      rescue Exception => e
        supervisor.terminate
        # Gracefully shut down
      end
    end
  end
end
