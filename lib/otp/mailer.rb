require 'action_mailer/railtie'
require_relative '../otp'

module OTP
  # OTP mailer.
  class Mailer < ActionMailer::Base
    append_view_path(OTP::PATH)

    default subject: 'Your magic password 🗝️'

    # Sends an email containing the OTP
    #
    # @param email [String] the email address to send to
    # @param otp_code [String] the OTP code to include
    # @param model [ActiveRecord::Base] model to expose
    # @param mail_opts [Hash] arbitrary options to pass to `mail()` method
    # @return [Mail] instance
    def otp(email, otp_code, model, mail_opts = {})
      @model = model
      @otp_code = otp_code

      mail(to: email, **mail_opts)
    end
  end
end
