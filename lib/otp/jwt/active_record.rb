require 'active_support/concern'

module OTP
  module JWT
    # [ActiveRecord] concern.
    module ActiveRecord
      extend ActiveSupport::Concern

      class_methods do
        # Returns a record based on the [JWT] token subject
        #
        # @param token [String] representing a [JWT] token
        # @return [ActiveRecord::Base] model
        def from_jwt(token)
          OTP::JWT::Token.decode(token) do |payload|
            self.find_by(id: payload['sub'])
          end
        end
      end

      # Returns a [JWT] token for this record
      #
      # @return [ActiveRecord::Base] model
      def to_jwt
        OTP::JWT::Token.sign(sub: self.id)
      end
    end
  end
end
