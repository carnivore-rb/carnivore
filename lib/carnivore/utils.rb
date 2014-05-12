require 'carnivore'

module Carnivore

  # Helper utilities
  module Utils
    autoload :Params, 'carnivore/utils/params'
    autoload :Logging, 'carnivore/utils/logging'
    autoload :MessageRegistry, 'carnivore/utils/message_registry'
    autoload :Smash, 'carnivore/utils/smash'

    extend Params
    extend Logging

  end
end
