require 'jwt'
require 'active_support/configurable'

module OTP
  module JWT
    # A configurable set of token helpers to sign/verify an entity JWT token.
    module Token
      include ActiveSupport::Configurable

      # Resolves possible JWT exception classes
      #
      # Can be removed once #255 is merged.
      # See: https://github.com/jwt/ruby-jwt/pull/255
      JWT_EXCEPTIONS = ::JWT.constants.map do |cname|
        klass = ::JWT.const_get(cname)
        klass if klass.is_a?(Class) && klass <= StandardError
      end.compact

      # The signature key used to sign the tokens.
      config_accessor :jwt_signature_key, instance_accessor: false
      # The signature key algorithm, defaults to HS256.
      config_accessor(:jwt_algorithm, instance_accessor: false) { 'HS256' }
      # The lifetime of the token, defaults to 1 day.
      config_accessor(:jwt_lifetime, instance_accessor: false) { 60 * 60 * 24 }

      # Generates a token based on a payload and optional overwritable claims
      #
      # @param payload [Hash], data to be encoded into the token.
      # @param claims [Hash], extra claims to be encoded into the token.
      #
      # @return [String], a JWT token
      def self.sign(payload, claims = {})
        payload = payload.merge(claims)
        claims[:exp] ||= self.jwt_lifetime if self.jwt_lifetime.present?

        ::JWT.encode(payload, self.jwt_signature_key, self.jwt_algorithm)
      end

      # Verifies and returns decoded token data upon success
      #
      # @param token [String], token to be decoded.
      # @param options [Hash], extra options to be used during verification.
      #
      # @return [Hash], JWT token payload
      def self.verify(token, options = {})
        lifetime = self.jwt_lifetime
        opts = {}.merge(options)
        opts[:verify_expiration] ||= lifetime if lifetime.present?

        ::JWT.decode(token.to_s, self.jwt_signature_key, true, opts)
      end

      # Decodes a valid token into [Hash]
      #
      # Requires a block, yields JWT data. Will catch any JWT exception.
      #
      # @param token [String], token to be decoded.
      # @param options [Hash], extra options to be used during verification.
      # @return [Hash] upon success
      def self.decode(token, options = nil)
        return unless block_given?
        verified, _ = self.verify(token, options || {})

        yield verified
      rescue *JWT_EXCEPTIONS
      end
    end
  end
end
