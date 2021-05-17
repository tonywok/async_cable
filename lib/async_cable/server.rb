require 'async/websocket/adapters/rack'
require 'async/redis'
require 'async/logger'

module AsyncCable
  class Server
    attr_reader :connections, :instances, :pubsub

    # TODO: Hack to make heroku redis work
    class AuthenticatedRESP2
      def initialize(credentials, protocol: Async::Redis::Protocol::RESP2)
        @credentials = credentials
        @protocol = protocol
      end
    
      def client(stream)
        client = @protocol.client(stream)
        client.write_request(["AUTH", *@credentials])
        client.read_response # Ignore response.
        return client
      end
    end

    def initialize
      @connections = Set.new
      @instances = {}
      @pubsub = if ENV["REDIS_URL"]
        uri = URI(ENV["REDIS_URL"])
        endpoint = Async::IO::Endpoint.tcp(uri.hostname, uri.port)
        Async::Redis::Client.new(endpoint, protocol: AuthenticatedRESP2.new([uri.password]))
      else
        Async::Redis::Client.new(Async::Redis.local_endpoint)
      end
    end

    def publish(key, message)
      pubsub.publish(key, JSON.dump(message))
    end

    def subscribe(key, &block)
      pubsub.subscribe(key, &block)
    end

    def call(env)
      response = Async::WebSocket::Adapters::Rack.open(env, protocols: ["actioncable-v1-json"]) do |websocket_connection|
        connection = ApplicationCable::Connection.new(self, env, websocket_connection)
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