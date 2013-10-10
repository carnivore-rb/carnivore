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
        case args[:queues]
        when Hash
          @queues = args[:queues]
        else
          @queues = Array(args[:queues]).flatten.compact
          @queues = Hash[*(
              @queues.size.times.map(&:to_i).zip(@queues).flatten
          )]
        end
        @queues.values.map do |q|
          q.replace(format_queue(q))
        end
        if(args[:processable_queues])
          @processable_queues = Array(args[:processable_queues]).flatten.compact
        end
        @pause_time = args[:pause] || 5
        @receive_timeout = after(args[:receive_timeout] || 30){ terminate }
        debug "Creating SQS source instance <#{name}>"
        debug "Handled queues: #{@queues.inspect}"
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
          msgs = queues.map do |q|
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
          else
            debug "Received: #{msgs.inspect}"
          end
          count += 1
        end
        msgs.map{|m| pre_process(m) }
      end

      def transmit(message, original=nil)
        queue = determine_queue(original)
        @fog.send_message(queue, message)
      end

      def confirm(message)
        queue = determine_queue(message)
        debug "Source<#{name}> Confirming message<#{message}> on Queue<#{queue}>"
        m = message.is_a?(Message) ? message[:message] : message
        @fog.delete_message(queue, m['ReceiptHandle'])
      end

      private

      def determine_queue(obj)
        queue = nil
        if(obj)
          if(obj.is_a?(Message))
            queue = obj[:message]['SourceQueue']
          else
            case obj
            when Numeric
              queue = @queues[dest]
            when String, Symbol
              queue = @queues[dest.to_s] || queues.detect{|q| q.end_with?(dest.to_s)}
            when Hash
              queue = obj['SourceQueue']
            end
          end
        end
        queue || queues.first
      end

      def queues
        if(@processable_queues)
          @queues.map do |k,v|
            v if @processable_queues.include?(k)
          end.compact
        else
          @queues.values
        end
      end

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
