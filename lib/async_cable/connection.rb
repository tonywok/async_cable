module AsyncCable
  class Connection
    AuthorizationError = Class.new(StandardError)

    attr_reader :server, :env, :websocket, :subscriptions, :ping_task

    def initialize(server, env, websocket)
      @server = server
      @env = env
      @websocket = websocket
      @subscriptions = Subscriptions.new(self)
      @ping_task = Utils::PeriodicTask.new(every: 3) { ping }
    end

    delegate :handle, to: :subscriptions
    delegate :pubsub, :publish, to: :server

    # TODO: USER LAND
    def authorize!
      raise AuthorizationError unless current_user.present?
      welcome
      ping_task.start
    end

    FakeUser = Struct.new(:id, keyword_init: true)
    def current_user
      @current_user ||= FakeUser.new(id: cookies.signed["user.id"])
    end
    # TODO: USER LAND

    def subscribe(key)
      Utils::Task.new do
        pubsub.subscribe(key) do |context|
          while true
            type, name, message = context.listen
            transmit(JSON.parse(message))
          end
        end
      end
    end

    def transmit(message)
      websocket.write(message)
      websocket.flush
    end

    def cleanup
      websocket.close
      ping.stop
      subscriptions.stop
    end

    private

    def request # :doc:
      @request ||= begin
        environment = Rails.application.env_config.merge(env) if defined?(Rails.application) && Rails.application
        ActionDispatch::Request.new(environment || env)
      end
    end

    # The cookies of the request that initiated the WebSocket connection. Useful for performing authorization checks.
    def cookies # :doc:
      request.cookie_jar
    end

    def welcome
      transmit({ type: 'welcome' })
    end

    def ping
      transmit({ type: 'ping', message: Time.now.to_i })
    end
  end
end