require 'mixlib/config'
require 'carnivore'

module Carnivore
  # Configuration helper
  class Config

    extend Mixlib::Config

    class << self

      # Set/get automatic symbolization of hash keys
      #
      # @param v [Object] truthy or falsey value
      # @return [TrueClass, FalseClass]
      # v:: Boolean value
      def auto_symbolize(v=nil)
        unless(v.nil?)
          @hash_symbolizer = !!v
        end
        @hash_symbolizer.nil? ? true : @hash_symbolizer
      end

      # Merge provided args into configuration
      #
      # @param args [Hash]
      # @return [self]
      def configure(args)
        build(args[:config_path]) if args[:config_path]
        self.merge!(args)
        self
      end

      # Populates the configuration
      #
      # @param path_or_hash [String, Hash] Path to JSON file or configuration hash
      # @return [self]
      def build(path_or_hash)
        if(path_or_hash.is_a?(Hash))
          conf = path_or_hash
        else
          if(File.directory?(path_or_hash.to_s))
            files = Dir.new(path_or_hash.to_s).find_all do |f|
              File.extname(f) == '.json'
            end.sort
            conf = files.inject(Smash.new) do |memo, path|
              memo.deep_merge!(
                MultiJson.load(
                  File.read(
                    File.join(
                      path_or_hash.to_s, path
                    )
                  )
                ).to_smash
              )
            end
            self.config_path = path_or_hash
          elsif(File.exists?(path_or_hash.to_s))
            conf = MultiJson.load(File.read(path_or_hash))
            self.config_path = path_or_hash
          else
            raise "Failed to load configuration file: #{path_or_hash}"
          end
        end
        conf.each do |k,v|
          self.send(k, v)
        end
        self
      end

      # Fetch value from configuration
      #
      # @param ary [String, Symbol] list of strings or symbols as hash path
      # @return [Object] return value or nil
      # @example
      #   Config.build(:my_app => {:port => 30})
      #   Config.get(:my_app, :port) => 30
      #   Config.get(:my_app, :host) => nil
      #   Config.get(:other_app, :port) => nil
      #   Config.get(:my_app, :mail, :server) => nil
      def get(*ary)
        value = Carnivore::Utils.retrieve(self, *ary)
        if(value.is_a?(Hash) && auto_symbolize)
          Smash.new(value)
        else
          value
        end
      end

    end
  end
end
