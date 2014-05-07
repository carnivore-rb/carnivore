require 'carnivore'
require 'celluloid/supervision_group'

module Carnivore
  class Supervisor < Celluloid::SupervisionGroup

    class << self

      # Build a new supervisor
      def build!
        _, s = create!
        supervisor(s)
      end

      # Create a new supervisor
      # Returns [registry,supervisor]
      def create!
        registry = Celluloid::Registry.new
        [registry, run!(registry)]
      end

      def supervisor(sup=nil)
        if(sup)
          Celluloid::Actor[:carnivore_supervisor] = sup
        end
        Celluloid::Actor[:carnivore_supervisor]
      end

      def registry(reg=nil)
        if(supervisor)
          supervisor.registry
        end
      end

      # Destroy the registered supervisor
      def terminate!
        if(supervisor)
          begin
            supervisor.terminate
          rescue Celluloid::DeadActorError => e
            Celluloid::Logger.warn "Default supervisor is already in dead state (#{e.class}: #{e})"
          end
          @supervisor = nil
          @registry = nil
        end
        true
      end

    end

    attr_reader :registry

    def [](k)
      registry[k]
    end

  end
end
