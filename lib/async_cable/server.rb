require 'async/websocket/adapters/rack'
require 'async/redis'
require 'async/logger'

module AsyncCable
  class Server
    attr_reader :connections, :instances, :pubsub

    def initialize
      @connections = Set.new
      @instances = {}
      @pubsub = Async::Redis::Client.new(Async::Redis.local_endpoint)
    end

    def publish(key, message)
      pubsub.publish(key, JSON.dump(message))
    end

    def call(env)
      response = Async::WebSocket::Adapters::Rack.open(env, protocols: ["actioncable-v1-json"]) do |websocket_connection|
        connection = Connection.new(self, env, websocket_connection)
        connection.authorize!
        connections << connection

        while payload = websocket_connection.read
          connection.handle(payload)
        end
      end

      response[1]['rack.hijack'] = lambda do |stream|
        response[2].call(stream)
      end

      [response[0], response[1], []]
    end
  end
end