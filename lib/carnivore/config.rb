require 'json'
require 'mixlib/config'

module Carnivore
  class Config

    extend Mixlib::Config

    class << self

      def configure(args)
        build(args[:config_path]) if args[:config_path]
        self.merge!(args)
        self
      end

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

      def get(*ary)
        ary.flatten.inject(self) do |memo, key|
          memo[key.to_s] || memo[key.to_sym] || break
        end
      end

    end
  end
end
