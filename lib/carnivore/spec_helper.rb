require 'carnivore'
require 'celluloid'
require 'minitest/autorun'

Celluloid.logger.level = 4

if(File.directory?(dir = File.join(Dir.pwd, 'test', 'specs')))
  Dir.glob(File.join(dir, '*.rb')).each do |path|
    require path
  end
else
  puts 'Failed to locate `test/specs` directory. Are you in project root directory?'
  exit -1
end

MiniTest::Spec.before do
  Celluloid.shutdown
  Celluloid.boot
end

# Simple waiter method to stall testing
def source_wait(name='wait')
  sleep(ENV.fetch("CARNIVORE_SOURCE_#{name.to_s.upcase}", 0.2).to_f)
end

# dummy store that should never be used for anything real
class MessageStore
  class << self

    def init
      @messages = []
    end

    def messages
      @messages
    end

  end
end

# dummy source to hold final tranmission and stuff in store
module Carnivore
  class Source
    class Spec < Source
      def setup(*args)
        MessageStore.init
      end

      def receive(*args)
        wait(:forever)
      end

      def transmit(*args)
        MessageStore.messages << args.first
      end
    end
  end
end

Carnivore::Source.provide(:spec, 'carnivore/spec_helper')