# require_relative "../config/environment"
# Rails.application.eager_load!

require "async_cable"

run AsyncCable.server
