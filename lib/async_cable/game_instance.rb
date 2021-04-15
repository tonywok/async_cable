module AsyncCable
  class GameInstance
    attr_reader :game, :player_channels, :player_keys

    delegate :start, :started?, :current_choice,
      to: :game

    def initialize(game:)
      @game = game
      @player_channels = {}
      @player_keys = [:p1, :p2].to_enum
    end

    def status
      return Status.running if game.started?
      return Status.waiting if player_channels.length != 2
      Status.ready
    end

    def join(player_channel_key)
      player_channels.fetch(player_channel_key) do
        player_channels[player_channel_key] = PlayerChannel.new(game_key: player_keys.next, channel_key: player_channel_key)
      end
    end

    def start
      decision = game.start
      messages = game.serializer.decision(decision)
      channel_messages(messages)
    end

    def decide(option)
      player, name, target = option.split(".")
      decision = game.decide(player, name, target)
      messages = game.serializer.decision(decision)
      channel_messages(messages)
    end

    def load(player_channel_key)
      player_game_key = _game_key(player_channel_key)
      channel_messages(game.serializer.load(player_game_key, game.current_choice))
    end

    private

    def _channel_key(game_key)
      player_channels.values.index_by(&:game_key).fetch(game_key).channel_key
    end

    def _game_key(channel_key)
      player_channels.values.index_by(&:channel_key).fetch(channel_key).game_key
    end

    def channel_messages(messages)
      Array.wrap(messages).map { |message| ChannelMessage.new(channel_key: _channel_key(message.recipient), message: message) }
    end

    PlayerChannel = Struct.new(:game_key, :channel_key, keyword_init: true)
    ChannelMessage = Struct.new(:channel_key, :message, keyword_init: true) do
      def as_json
        message.as_json
      end
    end
    Status = Struct.new(:status, keyword_init: true) do
      ALL = [
        :running,
        :waiting,
        :ready,
      ]

      ALL.each do |s|
        define_method("#{s}?") { s == status }
        define_singleton_method(s) { new(status: s) }
      end
    end
  end
end