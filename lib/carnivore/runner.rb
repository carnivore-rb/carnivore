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
      begin
        require 'carnivore/supervisor'
        Supervisor.run
      rescue Exception => e
        # Gracefully shut down
      end
    end
  end
end
