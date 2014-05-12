require 'carnivore'

module Carnivore
  class Source

    # Container for holding source configuration. This allows setup to
    # occur prior to the supervisor actually starting the sources
    class SourceContainer

      # @return [Class] class of Source
      attr_reader :klass
      # @return [Hash] configuration hash for Source
      attr_reader :source_hash

      # Create a new source container
      #
      # @param class_name [Class] class of Source
      # @param args [Hash] configuration hash for source
      def initialize(class_name, args={})
        @klass = class_name
        @source_hash = Smash.new(args || {})
        @source_hash[:callbacks] = Smash.new
      end

      # name:: Name of callback
      # klass:: Class of callback (optional)
      # Add a callback to a source via Class or block
      #
      # @param name [String, Symbol] name of callback
      # @param klass [Class] class of callback
      # @yield callback block
      # @yieldparam message [Carnivore::Message] message to process
      # @return [Class, Proc] callback registered
      def add_callback(name, klass=nil, &block)
        @source_hash[:callbacks][name] = klass || block
      end
    end

  end
end
