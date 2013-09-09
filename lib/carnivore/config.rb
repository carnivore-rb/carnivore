require 'json'
require 'mixlib/config'

module Carnivore
  class Config

    extend Mixlib::Config

    class << self

      def configure(args)
        build(args[:config_file]) if args[:config_file]
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
        path_or_hash.each do |k,v|
          self[k] = v
        end
        self
      end

      def get(*ary)
        ary.flatten.inject(self) do |memo, key|
          memo[key] || break
        end
      end

    end
  end
end
