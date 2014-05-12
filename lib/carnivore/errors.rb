require 'carnivore'

module Carnivore
  # Default Carnivore error class
  class Error < StandardError
    # Supervisor has died
    class DeadSupervisor < Error; end
  end
end
