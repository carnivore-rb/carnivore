require 'fog'
require 'carnivore/source'

module Carnivore
  class Source
    class Sqs < Source

      OUTPUT_REPEAT_EVERY=5

      attr_reader :pause_time

      def setup(args={})
        @fog = nil
        @connection_args = args[:fog]
        @queue = args[:queue_url]
        @pause_time = args[:pause] || 5
        @receive_timeout = after(args[:receive_timeout] || 30){ terminate }
        debug "Creating SQS source instance <#{name}>"
      end

      def connect
        @fog = Fog::AWS::SQS.new(@connection_args)
      end

      def receive(n=1)
        count = 0
        m = nil
        until(m)
          m = nil
          @receive_timeout.reset
          m = @fog.receive_message(@queue, 'MaxNumberOfMessages' => n).body['Message'].first
          @receive_timeout.reset
          unless(m)
            if(count == 0)
              debug "Source<#{name}> no message received. Sleeping for #{pause_time} seconds."
            elsif(count % OUTPUT_REPEAT_EVERY == 0)
              debug "Source<#{name}> last message repeated #{count} times"
            end
            sleep(pause_time)
          end
          count += 1
        end
        pre_process(m)
      end

      def send(message)
        @fog.send_message(@queue, message)
      end

      def confirm(message)
        @fog.delete_message(@queue, message['ReceiptHandle'])
      end

      private

      def fog
        unless(@fog)
          connect
        end
        @fog
      end

      def pre_process(m)
        if(m['Body'])
          begin
            m['Body'] = JSON.load(m['Body'])
          rescue JSON::ParserError
            # well, we did our best
          end
        end
        m
      end

    end
  end
end
