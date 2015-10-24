require 'carnivore'

module Carnivore
  class Supervisor < Zoidberg::Supervisor

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
      # @return [Array<[Zoidberg::Registry, Carnivore::Supervisor]>]
      def create!
        s = Carnivore::Supervisor.new
        [s.registry, s]
      end

      # Get/set the default supervisor
      #
      # @param sup [Carnivore::Supervisor]
      # @return [Carnivore::Supervisor]
      def supervisor(sup=nil)
        if(sup)
          @supervisor = sup
        end
        unless(@supervisor)
          raise Zoidberg::DeadException.new('Instance in terminated state!')
        end
        @supervisor
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
          rescue Zoidberg::DeadException => e
            Carnivore::Logger.warn "Default supervisor is already in dead state (#{e.class}: #{e})"
          end
          @supervisor = nil
        end
        true
      end

      # Check if default supervisor is alive
      #
      # @return [TrueClass, FalseClass]
      def alive?
        supervisor && supervisor.alive?
      end

    end
  end
end
