require 'carnivore'

module Carnivore

  module Utils
    autoload :Params, 'carnivore/utils/params'
    autoload :Logging, 'carnivore/utils/logging'
    autoload :MessageRegistry, 'carnivore/utils/message_registry'

    extend Params
    extend Logging

  end
end
