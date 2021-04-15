require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

require "active_support/all"

module AsyncCable
  module_function def server
    @server ||= Server.new
  end
end