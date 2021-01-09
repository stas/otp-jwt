lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'otp/jwt/version'

Gem::Specification.new do |spec|
  spec.name          = 'otp-jwt'
  spec.version       = OTP::JWT::VERSION
  spec.authors       = ['Stas Suscov']
  spec.email         = ['stas@nerd.ro']

  spec.summary       = 'Passwordless HTTP APIs'
  spec.description   = 'OTP (email, SMS) JWT authentication for HTTP APIs.'
  spec.homepage      = 'https://github.com/stas/otp-jwt'
  spec.license       = 'MIT'

  spec.files         = Dir.glob('{lib,spec}/**/*', File::FNM_DOTMATCH)
  spec.files        += %w(LICENSE.txt README.md)
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'jwt', '~> 2'
  spec.add_dependency 'rotp', '~> 6'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'ffaker'
  spec.add_development_dependency 'rails', ENV['RAILS_VERSION']
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rubocop', ENV['RUBOCOP_VERSION']
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rails_config'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'sqlite3', ENV['SQLITE3_VERSION']
  spec.add_development_dependency 'tzinfo-data'
  spec.add_development_dependency 'yardstick'
end
