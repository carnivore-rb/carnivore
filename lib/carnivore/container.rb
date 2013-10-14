require 'carnivore/utils'
require 'celluloid/logger'

module Carnivore
  class Container < Module

    include Carnivore::Utils::Logging

    class << self
      def log
        Celluloid::Logger
      end
    end
    def log
      Celluloid::Logger
    end
  end
end
