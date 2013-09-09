require 'reel'
require 'carnivore/source'

module Carnivore

  class ReelServer < Reel::Server

    def initialize(host, port, source_name)
      @source_name = source_name.to_sym
      super(host, port, &method(:on_connection))
    end

    def on_connection(con)
      con.each_request do |request|
        msg = format(request)
        callbacks = Celluloid::Actor[@source_name].callbacks.map do |c_name|
          [c_name, Celluloid::Actor[@source_name].callback_name(c_name)]
        end
        callbacks.each do |name, c_name|
          debug "Dispatching message<#{msg[:message].object_id}> to callback<#{name} (#{c_name})>"
          Celluloid::Actor[c_name].async.call(msg)
        end
      end
    end

  end

  class Http < Source

    attr_reader :args

    def setup(args={})
      @args = default_args(args)
    end

    def default_args(args)
      {
        :bind => '0.0.0.0',
        :port => '3000'
      }.merge(args)
    end

    def process(*process_args)
      ReelServer.new(args[:bind], args[:port], name)
    end

  end

end
