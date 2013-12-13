module Carnivore
  class Supervisor < Celluloid::SupervisionGroup

    class << self

      attr_reader :registry, :supervisor

      # Build a new supervisor
      def build!
        @registry, @supervisor = create!
      end

      # Create a new supervisor
      # Returns [registry,supervisor]
      def create!
        registry = Celluloid::Registry.new
        [registry, run!(registry)]
      end

    end

    # name:: Name of source
    # Return source
    def [](name)
      instance = @registry[name]
      unless(instance)
        if(member = @members.detect{|m| m && m.name.to_s == name.to_s})
          Celluloid::Logger.warn "Found missing actor in member list. Attempting to restart manually."
          restart_actor(member.actor, true)
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
