require 'json'

module Carnivore
  class Config
    class << self
      def configure(path_or_hash)
        if(path_or_hash.is_a?(Hash))
          @config = path_or_hash
        else
          if(File.exists?(path_or_hash.to_s))
            @config = JSON.load(File.read(path_or_hash))
            @path = path_or_hash
          else
            raise "Failed to load configuration file: #{path_or_hash}"
          end
        end
      end

      def [](k)
        @config ? @config[k] : nil
      end

      def path
        @path
      end
    end
  end
end
