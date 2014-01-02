module Carnivore
  module Utils

    module Params

      # hash:: Hash
      # Symbolize keys in hash
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

      # hash:: Hash
      # args:: Symbols or strings
      # Follow path in hash provided by args and return value or nil
      # if path is not valid
      def retrieve(hash, *args)
        valids = [::Hash, hash.is_a?(Class) ? hash : hash.class]
        args.flatten.inject(hash) do |memo, key|
          break unless valids.detect{ |valid_type|
            memo.is_a?(valid_type) || memo == valid_type
          }
          memo[key.to_s] || memo[key.to_sym] || break
        end
      end
    end

  end
end
