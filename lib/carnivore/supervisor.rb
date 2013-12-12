module Carnivore
  class Supervisor < Celluloid::SupervisionGroup

    class << self

      attr_reader :registry, :supervisor

      def build!
        @registry = Celluloid::Registry.new
        @supervisor = run!(@registry)
      end

    end

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
