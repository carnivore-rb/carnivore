require 'hashie'

module Carnivore
  module Utils

    # Customized Hash
    class Smash < Hash
      include Hashie::Extensions::IndifferentAccess
      include Hashie::Extensions::DeepMerge
      include Hashie::Extensions::Coercion

      coerce_value Hash, Smash

      # Create new instance
      #
      # @param args [Object] argument list
      def initialize(*args)
        base = nil
        if(args.first.is_a?(::Hash))
          base = args.shift
        end
        super *args
        if(base)
          self.replace(base)
        end
      end

      # Get value at given path
      #
      # @param args [String, Symbol] key path to walk
      # @return [Object, NilClass]
      def retrieve(*args)
        args.inject(self) do |memo, key|
          if(memo.is_a?(Hash))
            memo.to_smash[key]
          else
            nil
          end
        end
      end
      alias_method :get, :retrieve

      # Fetch value at given path or return a default value
      #
      # @param args [String, Symbol, Object] key path to walk. last value default to return
      # @return [Object] value at key or default value
      def fetch(*args)
        default_value = args.pop
        retrieve(*args) || default_value
      end

      # Set value at given path
      #
      # @param args [String, Symbol, Object] key path to walk. set last value to given path
      # @return [Object] value set
      def set(*args)
        unless(args.size > 1)
          raise ArgumentError.new 'Set requires at least one key and a value'
        end
        value = args.pop
        set_key = args.pop
        leaf = args.inject(self) do |memo, key|
          unless(memo[key].is_a?(Hash))
            memo[key] = Smash.new
          end
          memo[key]
        end
        leaf[set_key] = value
        value
      end

    end
  end

end

# Hook helper into toplevel `Hash`
class Hash

  # Convert to Smash
  #
  # @return [Smash]
  def to_smash
    ::Smash.new.replace(self)
  end
  alias_method :hulk_smash, :to_smash

end

Smash = Carnivore::Utils::Smash
