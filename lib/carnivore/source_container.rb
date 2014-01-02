require 'carnivore'

module Carnivore
  class Source

    # Container for holding source configuration. This allows setup to
    # occur prior to the supervisor actually starting the sources
    class SourceContainer

      attr_reader :klass
      attr_reader :source_hash

      # class_name:: Name of source class
      # args:: argument hash to pass to source instance
      def initialize(class_name, args={})
        @klass = class_name
        @source_hash = args || {}
        @source_hash[:callbacks] = {}
      end

      # name:: Name of callback
      # klass:: Class of callback (optional)
      # Add a callback to a source via Class or block
      def add_callback(name, klass=nil, &block)
        @source_hash[:callbacks][name] = klass || block
      end
    end

  end
end
