require 'celluloid/logger'

module Carnivore
  class Container < Module

    include Celluloid::Logger

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
