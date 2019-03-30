require 'active_record/railtie'
require 'action_controller/railtie'
require 'global_id/railtie'
require 'otp/mailer'

Rails.logger = Logger.new(STDOUT)
Rails.logger.level = ENV['LOG_LEVEL'] || Logger::WARN

ActiveRecord::Base.logger = Rails.logger
ActiveRecord::Base.establish_connection(
  ENV['DATABASE_URL'] || 'sqlite3::memory:'
)

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :email
    t.string :full_name
    t.string :phone_number
    t.string :otp_secret
    t.integer :otp_counter, default: 0
    t.timestamp :last_login_at
    t.timestamps
  end
end

class User < ActiveRecord::Base
  include GlobalID::Identification
  include OTP::ActiveRecord
  include OTP::JWT::ActiveRecord

  def email_otp
    OTP::Mailer.otp(email, otp, self).deliver_later
  end
end

class Dummy < Rails::Application
  secrets.secret_key_base = '_'

  routes.draw do
    resources :users, only: [:index]
    resources :tokens, only: [:create]
  end
end

GlobalID.app = Dummy

class ApplicationController < ActionController::API
  include OTP::JWT::ActionController

  private

  def current_user
    @jwt_user ||= User.from_jwt(request_authorization_header)
  end

  def current_user!
    current_user || raise('User authentication failed')
  rescue
    head(:unauthorized)
  end
end

class UsersController < ApplicationController
  before_action :current_user!

  def index
    render json: current_user
  end
end

class TokensController < ApplicationController
  def create
    user = User.find_by(email: params[:email])
    jwt_from_otp(user, params[:otp]) do |auth_user|
      auth_user.update_column(:last_login_at, DateTime.current)

      render json: { token: auth_user.to_jwt }, status: :created
    end
  end
end
