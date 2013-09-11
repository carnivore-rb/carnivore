require 'fog'
require 'carnivore/source'

module Carnivore
  class Source
    class RabbitMq < Source

      def setup(args={})
        @bunny = nil
        @connection_args = args[:bunny]
        @queue_name = args[:queue]
        @exchange_name = args[:exchange]
        debug "Creating RabbitMq source instance <#{name}>"
      end

      def connect
        @bunny = Bunny.new(@connection_args)
        @bunny.start
        @channel = @bunny.create_channel
        @exchange = @channel.topic(@exchange_name)
        @queue = @channel.queue(@queue_name).bind(@exchange) # TODO: Add topic key
      end

      def process
        @queue.subscribe do |info, metadata, payload|
          msg = format(payload)
          callbacks.each do |name|
            c_name = callback_name(name)
            debug "Dispatching message<#{msg[:message].object_id}> to callback<#{name} (#{c_name})>"
            Celluloid::Actor[c_name].async.call(msg)
          end
        end
      end

    end
  end
end
