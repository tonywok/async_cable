module AsyncCable
  class Subscriptions
    attr_reader :connection, :subscriptions

    def initialize(connection)
      @connection = connection
      @subscriptions = {}
    end

    def handle(payload)
      command = Command.make(payload)
      case command.name
      when Command::Names::SUBSCRIBE then add(command)
      when Command::Names::UNSUBSCRIBE then remove(command)
      when Command::Names::MESSAGE then perform(command)
      else
        raise "error executing command #{command}"
      end
    end

    def add(command)
      return if subscriptions.key?(command.key)

      channel_klass = command.channel.safe_constantize
      channel = channel_klass.new(connection: connection, identifier: command)
      subscriptions[command.key] = channel
      channel.subscribe
    end

    def remove(command)
      subscriptions.delete(command.key)
      subscription.unsubscribe
    end

    def perform(command)
      channel = subscriptions.fetch(command.key)
      action = command.data.fetch("action")

      channel.public_send(action, **command.data.symbolize_keys.except(:action))
    end

    def stop
      subscriptions.values.each(&:unsubscribe)
    end
  end
end