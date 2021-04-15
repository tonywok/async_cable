require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

require "active_support/all"

module AsyncCable
  module_function def server
    @server ||= Server.new
  end

  module_function def instance(game)
    server.instances[game.id] ||= GameInstance.new(game: game)
  end
end