require 'json'
require 'mixlib/config'

module Carnivore
  class Config

    extend Mixlib::Config

    class << self

      def auto_symbolize(v=nil)
        unless(v.nil?)
          @hash_symbolizer = !!v
        end
        @hash_symbolizer.nil? ? false : @hash_symbolizer
      end

      # args:: configuration hash
      # Merge provided args into configuration
      def configure(args)
        build(args[:config_path]) if args[:config_path]
        self.merge!(args)
        self
      end

      # path_or_hash:: Path to JSON file or configuration Hash
      # Populates the configuration
      def build(path_or_hash)
        if(path_or_hash.is_a?(Hash))
          conf = path_or_hash
        else
          if(File.exists?(path_or_hash.to_s))
            conf = JSON.load(File.read(path_or_hash))
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

      # ary: keys into a hash
      # Returns value if exists or nil
      #  Example:
      #    Config.build(:my_app => {:port => 30})
      #    Config.get(:my_app, :port) => 30
      #    Config.get(:my_app, :host) => nil
      #    Config.get(:other_app, :port) => nil
      #    Config.get(:my_app, :mail, :server) => nil
      def get(*ary)
        value = ary.flatten.inject(self) do |memo, key|
          memo[key.to_s] || memo[key.to_sym] || break
        end
        if(value.is_a?(Hash) && auto_symbolize)
          Carnivore::Utils.symbolize_hash(value)
        else
          value
        end
      end

    end
  end
end
