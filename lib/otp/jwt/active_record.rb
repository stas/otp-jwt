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
        # @param claim_name [String] the claim name to be used, default is `sub`
        # @return [ActiveRecord::Base] model
        def from_jwt(token, claim_name = 'sub')
          OTP::JWT::Token.decode(token) do |payload|
            self.find_by(id: payload[claim_name])
          end
        end
      end

      # Returns a [JWT] token for this record
      #
      # @param claims [Hash] extra claims to be included
      # @return [ActiveRecord::Base] model
      def to_jwt(claims = nil)
        claims ||= {}
        OTP::JWT::Token.sign(sub: self.id, **claims)
      end
    end
  end
end
