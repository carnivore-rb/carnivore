require 'carnivore'
require 'celluloid/supervision_group'

module Carnivore
  class Supervisor < Celluloid::SupervisionGroup

    class << self

      # Build a new supervisor
      #
      # @return [Carinvore::Supervisor]
      def build!
        _, s = create!
        supervisor(s)
      end

      # Create a new supervisor
      #
      # @return [Array<[Celluloid::Registry, Carnivore::Supervisor]>]
      def create!
        registry = Celluloid::Registry.new
        [registry, run!(registry)]
      end

      # Get/set the default supervisor
      #
      # @param sup [Carnivore::Supervisor]
      # @return [Carnivore::Supervisor]
      def supervisor(sup=nil)
        if(sup)
          Celluloid::Actor[:carnivore_supervisor] = sup
        end
        Celluloid::Actor[:carnivore_supervisor]
      end

      # Get the registry of the default supervisor
      #
      # @return [Celluloid::Registry, NilClass]
      def registry
        if(supervisor)
          supervisor.registry
        end
      end

      # Destroy the registered default supervisor
      #
      # @return [TrueClass]
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

    # @return [Celluloid::Registry]
    attr_reader :registry

    # Fetch actor from registry
    #
    # @param k [String, Symbol] identifier
    # @return [Celluloid::Actor, NilClass]
    def [](k)
      registry[k]
    end

  end
end
