require 'carnivore'
require 'celluloid/logger'

module Carnivore
  # Module used for building isolation
  class Container < Module

    include Carnivore::Utils::Logging
    # @!parse include Carnivore::Utils::Logging

    class << self

      # @return [Celluloid::Logger]
      def log
        Celluloid::Logger
      end

    end

    # @return [Celluloid::Logger]
    def log
      Celluloid::Logger
    end

  end
end
