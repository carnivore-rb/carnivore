module Carnivore
  class Error < StandardError
    class DeadSupervisor < Error; end
  end
end
