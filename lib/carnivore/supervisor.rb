require 'carnivore'
require 'celluloid/supervision_group'

module Carnivore
  class Supervisor < Celluloid::SupervisionGroup

    class << self

      # Build a new supervisor
      def build!
        r, s = create!
        registry(r)
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
          Thread.current[:carnivore_supervisor] = sup
        end
        Thread.current[:carnivore_supervisor]
      end

      def registry(reg=nil)
        if(reg)
          Thread.current[:carnivore_registry] = reg
        end
        Thread.current[:carnivore_registry]
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
          begin
            member.restart
            instance = @registry[name]
            unless(instance)
              Celluloid::Logger.error "Actor restart failed to make it available in the registry! (#{name})"
              raise KeyError.new("Failed to locate requested member in supervision group! (#{name})")
            end
          rescue => e
            Celluloid::Logger.error "Actor restart failure: #{e.class}: #{e}"
            Celluloid::Logger.debug "Actor restart backtrace: #{e.class}: #{e}\n#{e.backtrace.join("\n")}"
            abort e
          end
        end
      end
      instance
    end

  end
end
