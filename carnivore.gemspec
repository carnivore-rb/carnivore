$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'carnivore/version'
Gem::Specification.new do |s|
  s.name = 'carnivore'
  s.version = Carnivore::VERSION.version
  s.summary = 'Message processing helper'
  s.author = 'Chris Roberts'
  s.email = 'chrisroberts.code@gmail.com'
  s.homepage = 'https://github.com/carnivore-rb/carnivore'
  s.description = 'Message processing helper'
  s.license = 'Apache 2.0'
  s.require_path = 'lib'
  s.add_dependency 'celluloid', '~> 0.16.0'
  s.add_dependency 'bogo-config'
  s.add_dependency 'multi_json'
  s.add_dependency 'hashie'
  s.files = Dir['lib/**/*'] + %w(carnivore.gemspec README.md CHANGELOG.md)
end
