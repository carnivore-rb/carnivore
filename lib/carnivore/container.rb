require 'carnivore'

module Carnivore
  # Module used for building isolation
  class Container < Module

    include Carnivore::Utils::Logging
    # @!parse include Carnivore::Utils::Logging

    class << self

      # @return [Logger]
      def log
        Carnivore::Utils::Logging::Logger
      end

    end

    # @return [Logger]
    def log
      Carnivore::Utils::Logging::Logger
    end

  end
end
