require 'jwt'
require 'active_support/configurable'

module OTP
  module JWT
    # A configurable set of token helpers to sign/verify an entity JWT token.
    module Token
      include ActiveSupport::Configurable

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
      def self.sign(payload)
        payload = payload.dup.as_json

        if payload['exp'].blank? && self.jwt_lifetime.to_i > 0
          payload['exp'] = Time.now.to_i + self.jwt_lifetime
        end

        ::JWT.encode(payload, self.jwt_signature_key, self.jwt_algorithm)
      end

      # Verifies and returns decoded token data upon success
      #
      # @param token [String], token to be decoded.
      # @param opts [Hash], extra options to be used during verification.
      #
      # @return [Hash], JWT token payload
      def self.verify(token, opts = nil)
        verify = self.jwt_algorithm != 'none'
        opts ||= { algorithm: self.jwt_algorithm }

        ::JWT.decode(token.to_s, self.jwt_signature_key, verify, opts)
      end

      # Decodes a valid token into [Hash]
      #
      # Requires a block, yields JWT data. Will catch any JWT exception.
      #
      # @param token [String], token to be decoded.
      # @param opts [Hash], extra options to be used during verification.
      # @return [Hash] upon success
      def self.decode(token, opts = nil)
        verified, _ = self.verify(token, opts)

        if block_given?
          yield verified
        else
          verified
        end
      rescue ::JWT::EncodeError, ::JWT::DecodeError
      end
    end
  end
end
