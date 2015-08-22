# Load supporters on demand
autoload :MultiJson, 'multi_json'

require 'securerandom'
require 'zoidberg'
require 'bogo-config'
require 'carnivore/runner'
require 'carnivore/version'

# Message consumer and processor
module Carnivore
  autoload :Callback, 'carnivore/callback'
  autoload :Container, 'carnivore/container'
  autoload :Error, 'carnivore/errors'
  autoload :Logger, 'carnivore/logger'
  autoload :Message, 'carnivore/message'
  autoload :Source, 'carnivore/source'
  autoload :Supervisor, 'carnivore/supervisor'
  autoload :Utils, 'carnivore/utils'
  autoload :Version, 'carnivore/version'

  def self.uuid
    Zoidberg.uuid
  end

end
