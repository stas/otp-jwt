require 'bundler/setup'
require 'simplecov'

SimpleCov.start do
  add_group 'Lib', 'lib'
  add_group 'Tests', 'spec'
end
SimpleCov.minimum_coverage 90

require 'otp'
require 'otp/jwt'
require 'otp/jwt/test_helpers'
require_relative 'dummy'
require 'ffaker'
require 'rspec/rails'

OTP::JWT::Token.jwt_signature_key = '_'
OTP::Mailer.default from: '_'
ActiveJob::Base.queue_adapter = :test
ActionMailer::Base.delivery_method = :test

module OTP::JWT::FactoryHelpers
  # Creates an user
  #
  # @return [User]
  def create_user
    User.create!(
      full_name: FFaker::Name.name,
      email: FFaker::Internet.email,
      phone_number: FFaker::PhoneNumber.phone_number
    )
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.mock_with :rspec
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include OTP::JWT::TestHelpers, type: :model
  config.include OTP::JWT::FactoryHelpers, type: :model
  config.include ActiveJob::TestHelper, type: :model

  config.include OTP::JWT::TestHelpers, type: :request
  config.include OTP::JWT::FactoryHelpers, type: :request
  config.include ActiveJob::TestHelper, type: :request
  config.include Dummy.routes.url_helpers, type: :request
end
