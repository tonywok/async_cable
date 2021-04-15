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
      Async::WebSocket::Adapters::Rack.open(env, protocols: ["actioncable-v1-json"]) do |websocket_connection|
        connection = Connection.new(self, env, websocket_connection)
        connection.authorize!
        connections << connection

        while payload = websocket_connection.read
          connection.handle(payload)
        end
      ensure
        connections.each(&:cleanup)
      end
    end
  end
end