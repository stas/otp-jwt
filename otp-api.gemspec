lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'otp/api/version'

Gem::Specification.new do |spec|
  spec.name          = 'otp-api'
  spec.version       = OTP::API::VERSION
  spec.authors       = ['Stas Suscov']
  spec.email         = ['stas@nerd.ro']

  spec.summary       = 'Passwordless HTTP APIs'
  spec.description   = 'OTP (email, SMS) authentication support for HTTP APIs.'
  spec.homepage      = 'https://github.com/stas/otp-api'
  spec.license       = 'TBD'

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'jwt', '~> 2.1'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'ffaker'
  spec.add_development_dependency 'rails'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rails_config'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'sqlite3', '~> 1.3.6'
  spec.add_development_dependency 'yardstick'
end
