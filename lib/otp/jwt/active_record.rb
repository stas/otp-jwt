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
            val = payload[claim_name]
            pk_col = self.column_for_attribute(self.primary_key)

            # Arel casts the values to the primary key type,
            # which means that an UUID becomes an integer by default...
            if self.connection.respond_to?(:lookup_cast_type_from_column)
              pk_type = self.connection.lookup_cast_type_from_column(pk_col)
              casted_val = pk_type.serialize(val)
            else
              casted_val = self.connection.type_cast(val, pk_col)
            end

            return if casted_val.to_s != val.to_s.strip

            self.find_by(self.primary_key => val)
          end
        end
      end

      # Returns a [JWT] token for this record
      #
      # @param claims [Hash] extra claims to be included
      # @return [ActiveRecord::Base] model
      def to_jwt(claims = nil)
        OTP::JWT::Token.sign(
          sub: self.send(self.class.primary_key),
          **(claims || {})
        )
      end
    end
  end
end
