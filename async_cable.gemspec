require_relative 'lib/async_cable/version'

Gem::Specification.new do |spec|
  spec.name          = "async_cable"
  spec.version       = AsyncCable::VERSION
  spec.authors       = ["Tony Schneider"]
  spec.email         = ["tonywok@gmail.com"]

  spec.summary       = "Experimenting with an action cable compatible websocket server using socketry"
  spec.homepage      = "https://github.com/tonywok/async_cable"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["homepage_uri"] = spec.homepage

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "actionpack"

  spec.add_dependency "async-websocket"
  spec.add_dependency "async-redis"
  spec.add_dependency "falcon"
  spec.add_dependency "zeitwerk"

  spec.add_development_dependency "rspec"
end
