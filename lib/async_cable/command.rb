module AsyncCable
  class Command
    module Names
      SUBSCRIBE = "subscribe"
      UNSUBSCRIBE = "unsubscribe"
      MESSAGE = "message"
    end

    def self.make(payload)
      payload.stringify_keys!
      cable_identifier = JSON.parse(payload.fetch("identifier"))
      new(
        channel: cable_identifier.fetch("channel"),
        channel_id: cable_identifier.fetch("id"),
        name: payload.fetch("command"),
        data: payload.key?("data") ? JSON.parse(payload.fetch("data")) : {},
      )
    rescue => e
      Async.logger.info(self) { payload.to_s }
      raise e
    end

    attr_reader :channel, :channel_id, :name, :data

    def initialize(channel:, channel_id:, name:, data:)
      @channel = channel
      @channel_id = channel_id
      @name = name
      @data = data
    end

    def key
      [channel, channel_id].join(":")
    end

    def cable_identifier
      {
        channel: channel,
        id: channel_id
      }
    end
  end
end