module Carnivore
  module Utils

    # Parameter helper methods generally aimed at Hash instances
    module Params

      # Symbolize keys in hash
      #
      # @param hash [Hash]
      # @return [Hash] new hash instance with symbolized keys
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

      # Retrieve value in hash at given path
      #
      # @param hash [Hash] hash to walk into
      # @param args [String, Symbol] argument list to walk in hash
      # @return [Object, NilClass]
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
