# Load supporters on demand
autoload :Celluloid, 'celluloid'
autoload :MultiJson, 'multi_json'

require 'bogo-cli'
require 'bogo-config'
require 'carnivore/runner'
require 'carnivore/version'

# Message consumer and processor
module Carnivore
  autoload :Callback, 'carnivore/callback'
  autoload :Container, 'carnivore/container'
  autoload :Error, 'carnivore/errors'
  autoload :Message, 'carnivore/message'
  autoload :Source, 'carnivore/source'
  autoload :Supervisor, 'carnivore/supervisor'
  autoload :Utils, 'carnivore/utils'
  autoload :Version, 'carnivore/version'
end
