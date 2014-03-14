require 'carnivore'
require 'celluloid/supervision_group'

module Carnivore
  class Supervisor < Celluloid::SupervisionGroup

    class << self

      attr_reader :registry, :supervisor

      # Build a new supervisor
      def build!
        @registry, @supervisor = create!
        @supervisor
      end

      # Create a new supervisor
      # Returns [registry,supervisor]
      def create!
        registry = Celluloid::Registry.new
        [registry, run!(registry)]
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

    # name:: Name of source
    # Return source
    def [](name)
      instance = @registry[name]
      unless(instance)
        if(member = @members.detect{|m| m && m.name.to_s == name.to_s})
          Celluloid::Logger.warn "Found missing actor in member list. Attempting to restart manually."
          member.restart
          instance = @registry[name]
          unless(instance)
            Celluloid::Logger.error "Actor restart failed to make it available in the registry! (#{name})"
          end
        end
      end
      instance
    end

  end
end
