module AsyncCable
  class Channel
    attr_reader :identifier, :connection

    delegate :key, :cable_identifier, to: :identifier
    delegate :current_user, to: :connection

    def initialize(identifier:, connection:)
      @identifier = identifier
      @connection = connection
      self.confirmed = false
      self.rejected = false
    end

    def subscribe
      subscribed
      if rejected?
        reject_subscription
      else
        confirm_subscription
      end
    end

    def unsubscribe
      unsubscribed
      streams.values.each(&:stop)
    end

    def broadcast(key, message)
      connection.publish(key, {
        message: message,
        identifier: cable_identifier.to_json,
      })
    end

    def stream_from(key)
      streams[key] = connection.subscribe(key).start
    end

    private

    ## callbacks
    #
    def subscribed; end
    def unsubscribed; end

    def streams
      @streams ||= {}
    end

    ## Confirming/Rejecting Subscription
    #
    attr_accessor :confirmed, :rejected

    def confirm!
      confirm_subscription
    end

    def confirmed?
      !!confirmed
    end

    def reject!
      reject_subscription
    end

    def rejected?
      !!rejected
    end

    def confirm_subscription
      return if rejected?
      return if confirmed?
      self.confirmed = true
      transmit_subscription_confirmed
    end

    def reject_subscription
      # TODO: remove subscription from connection
      self.rejected = true
      transmit_subscription_rejected
    end

    def transmit_subscription_confirmed
      connection.transmit({
        identifier: cable_identifier.to_json,
        type: "confirm_subscription"
      })
    end

    def transmit_subscription_rejected
      connection.transmit({
        identifier: cable_identifier.to_json,
        type: "reject_subscription"
      })
    end
  end
end