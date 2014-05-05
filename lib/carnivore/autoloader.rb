# Register all base autoloading requirements

module Carnivore
  autoload :Config, 'carnivore/config'
  autoload :Callback, 'carnivore/callback'
  autoload :Container, 'carnivore/container'
  autoload :Error, 'carnivore/errors'
  autoload :Message, 'carnivore/message'
  autoload :Source, 'carnivore/source'
  autoload :Supervisor, 'carnivore/supervisor'
  autoload :Utils, 'carnivore/utils'
  autoload :Version, 'carnivore/version'
end

autoload :Smash, 'carnivore/utils/smash'
