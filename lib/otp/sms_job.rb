require 'active_job/railtie'
begin
  require 'aws-sdk-sns'
rescue LoadError => err
  (Rails.logger || Logger.new(STDOUT)).error(err)
end

module OTP
  # Uses the AWS SNS API to send the OTP SMS message.
  class SMSJob < ActiveJob::Base
    # A generic template for the message body.
    TEMPLATE = '%{otp} is your magic password 🗝️'
    # Indicates if the messaging is disabled. Handy for testing purposes.
    ENABLED = true

    # Sends the SMS message with the OTP code
    #
    # @return nil
    def perform(phone_number, otp_code, template = TEMPLATE)
      message = template % { otp: otp_code }

      Aws::SNS::Client.new(region: ENV['AWS_SMS_REGION']).publish(
        message: message,
        phone_number: phone_number
      ) if ENABLED
    end
  end
end
