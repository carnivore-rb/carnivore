require 'fog'
require 'carnivore/source'

module Carnivore
  class Source
    class Sqs < Source

      OUTPUT_REPEAT_EVERY=20

      attr_reader :pause_time

      def setup(args={})
        @fog = nil
        @connection_args = args[:fog]
        @queues = Array(args[:queues]).compact.flatten
        @queues.map! do |q|
          format_queue(q)
        end
        @pause_time = args[:pause] || 5
        @receive_timeout = after(args[:receive_timeout] || 30){ terminate }
        debug "Creating SQS source instance <#{name}>"
      end

      def format_queue(q)
        q.include?('.com') ? q : "/#{q.split(':')[-2,2].join('/')}"
      end

      def connect
        @fog = Fog::AWS::SQS.new(@connection_args)
      end

      def receive(n=1)
        count = 0
        msgs = []
        while(msgs.empty?)
          msgs = []
          @receive_timeout.reset
          msgs = @queues.map do |q|
            m = @fog.receive_message(q, 'MaxNumberOfMessages' => n).body['Message']
            m.map! do |msg|
              msg.merge('SourceQueue' => q)
            end
          end.flatten.compact
          @receive_timeout.reset
          if(msgs.empty?)
            if(count == 0)
              debug "Source<#{name}> no message received. Sleeping for #{pause_time} seconds."
            elsif(count % OUTPUT_REPEAT_EVERY == 0)
              debug "Source<#{name}> last message repeated #{count} times"
            end
            sleep(pause_time)
          end
          count += 1
        end
        msgs.map{|m| pre_process(m) }
      end

      def transmit(message, dest=nil)
        case dest
        when Numeric
          queue = @queues[dest]
        when String
          queue = @queues.detect{|q| q.include?(dest)}
        else
          queue = @queues.first
        end
        @fog.send_message(queue, message)
      end

      def confirm(message)
        @fog.delete_message(message['SourceQueue'], message['ReceiptHandle'])
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
