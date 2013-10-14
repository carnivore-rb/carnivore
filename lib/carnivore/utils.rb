require 'celluloid'

module Carnivore
  module Utils

    module Params
      def symbolize_hash(hash)
        Hash[*(
            hash.map do |k,v|
              if(k.is_a?(String))
                key = k.gsub(/(?<![A-Z])([A-Z])/, '_\1').sub(/^_/, '').downcase.to_sym
              else
                key = k
              end
              [
                key,
                v.is_a?(Hash) ? symbolize_hash(v) : v
              ]
            end.flatten(1)
        )]
      end
    end

    module Logging

      %w(debug info warn error).each do |key|
        define_method(key) do |string|
          log(key, string)
        end
      end

      def log(*args)
        if(args.empty?)
          Celluloid::Logger
        else
          severity, string = args
          Celluloid::Logger.send(severity.to_sym, "#{self}: #{string}")
        end
      end

    end
  end
end
