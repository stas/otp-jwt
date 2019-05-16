require 'json'

module OTP
  module JWT
    # Helpers to help you test the [JWT] requests.
    module TestHelpers
      # Helper provides JSON content type headers
      #
      # @return [Hash] the relevant content type &co
      def json_headers
        { 'Content-Type': Mime[:json].to_s }
      end

      # Helper to handle authentication requests easier
      #
      # @return [Hash] the authorization headers
      def jwt_auth_header(entity_or_subject)
        return json_headers unless entity_or_subject.present?

        token = entity_or_subject.try(:to_jwt)
        token ||= OTP::JWT::Token.sign(sub: entity_or_subject)

        { 'Authorization': "Bearer #{token}" }.merge(json_headers)
      end

      # Parses and returns a deserialized JSON
      #
      # @return [Hash]
      def response_json
        JSON.parse(response.body)
      end
    end
  end
end
