require 'rotp'
require 'active_support/concern'
require 'active_support/configurable'

module OTP
  # [ActiveRecord] concern.
  module ActiveRecord
    include ActiveSupport::Configurable
    extend ActiveSupport::Concern

    # Length of the generated OTP, defaults to 4.
    OTP_DIGITS = 4

    included do
      after_initialize :setup_otp
    end

    # Generates the OTP
    #
    # @return [String] or nil if no OTP is set
    def otp
      return nil if !valid? || !persisted? || otp_secret.blank?

      otp_digits = self.class.const_get(:OTP_DIGITS)
      hotp = ROTP::HOTP.new(otp_secret, digits: otp_digits)

      transaction do
        increment!(:otp_counter)
        hotp.at(otp_counter)
      end
    end

    # Verifies the OTP
    #
    # @return true on success, false on failure
    def verify_otp(otp)
      return nil if !valid? || !persisted? || otp_secret.blank?

      otp_digits = self.class.const_get(:OTP_DIGITS)
      hotp = ROTP::HOTP.new(otp_secret, digits: otp_digits)
      transaction do
        otp_status = hotp.verify(otp.to_s, otp_counter)
        increment!(:otp_counter)
        otp_status
      end
    end

    # Helper to send the OTP using the SMS job
    #
    # Does nothing. Implement your own handler.
    #
    # @return [OTP::API::SMSOTPJob] instance of the job
    def sms_otp
    end

    # Helper to email the OTP using a job
    #
    # Does nothing. Implement your own handler.
    #
    # @return [OTP::API::Mailer] instance of the job
    def email_otp
    end

    # Helper to deliver the OTP
    #
    # Will use the SMS job if the phone number is available.
    # Will default to the email delivery.
    #
    # @return [ActiveJob::Base] instance of the job
    def deliver_otp
      return unless persisted?
      sms_otp || email_otp || raise(NotImplementedError, self)
    end

    private
    # Provides a default value for the OTP secret attribute
    #
    # @return [String]
    def setup_otp
      self.otp_secret ||= ROTP::Base32.random_base32
      self.otp_counter ||= 0
    end
  end
end
