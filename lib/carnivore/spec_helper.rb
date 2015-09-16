require 'carnivore'
require 'minitest/autorun'

Zoidberg.logger.level = ENV['DEBUG'] ? 0 : 4

if(File.directory?(dir = File.join(Dir.pwd, 'test', 'specs')))
  Dir.glob(File.join(dir, '*.rb')).each do |path|
    require path
  end
else
  puts 'Failed to locate `test/specs` directory. Are you in project root directory?'
  exit -1
end

# Simple waiter method to stall testing
#
# @param name [String, Symbol] fetch wait time from environment variable
# @return [Numeric] seconds sleeping
def source_wait(name='wait')
  if(name.is_a?(String) || name.is_a?(Symbol))
    total = ENV.fetch("CARNIVORE_SOURCE_#{name.to_s.upcase}", 1.0).to_f
  else
    total = name.to_f
  end
  if(block_given?)
    elapsed = 0.0
    until(yield || elapsed >= total)
      sleep(0.1)
      elapsed += 0.1
    end
    elapsed
  else
    sleep(total)
    total
  end
end

# Dummy message store used for testing
class MessageStore
  class << self

    # Initialize message storage
    #
    # @return [Array]
    def init
      @messages = []
    end

    # @return [Array] messages
    def messages
      @messages
    end

  end
end

module Carnivore
  class Source
    # Dummy source for testing used to capture payloads for inspection
    class Spec < Source

      # @return [Array] messages confirmed
      attr_reader :confirmed

      # Creates new spec source
      #
      # @param args [Object] argument list (passed to Source)
      # @yield source block (passed to Source)
      def initialize(*args, &block)
        super
        @confirmed = []
      end

      # Setup the message store for payload storage
      #
      # @return [Array] message storage
      def setup(*args)
        MessageStore.init
      end

      # Dummy receiver
      def receive(*args)
        wait(:forever)
      end

      # Capture messages transmitted
      #
      # @param args [Object] argument list
      # @return [TrueClass]
      def transmit(*args)
        MessageStore.messages << args.first
        true
      end

      # Format the message
      #
      # @param msg [Object] message payload
      # @return [Carnivore::Message]
      def format(msg)
        Message.new(
          :message => msg,
          :source => self
        )
      end

      # Capture confirmed messages
      #
      # @param payload [Object] payload of message
      # @param args [Object] argument list (unused)
      # @return [TrueClass]
      def confirm(payload, *args)
        confirmed << payload
        true
      end

    end
  end
end

Carnivore::Source.provide(:spec, 'carnivore/spec_helper')
