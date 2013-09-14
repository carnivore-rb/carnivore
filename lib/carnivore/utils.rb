module Carnivore
  module Utils

    module Params
      def symbolize_hash(hash)
        Hash[*(
            hash.map do |k,v|
              [
                k.gsub(/(?<![A-Z])([A-Z])/, '_\1').sub(/^_/, '').downcase.to_sym,
                v.is_a?(Hash) ? symbolize_hash(v) : v
              ]
            end.flatten(1)
        )]
      end
    end

  end
end
