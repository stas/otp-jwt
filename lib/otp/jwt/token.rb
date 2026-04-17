require 'jwt'

module OTP
  module JWT
    # A configurable set of token helpers to sign/verify an entity JWT token.
    module Token
      # The signature key used to sign the tokens
      #
      # @return [String], signature key
      def self.jwt_signature_key
        @jwt_signature_key
      end

      # Set the signature key used to sign the tokens
      #
      # @param value [String], signature key
      #
      # @return [String], signature key
      def self.jwt_signature_key=(value)
        @jwt_signature_key = value
      end

      # The signature key algorithm, defaults to HS256
      #
      # @return [String], signature key algorithm
      def self.jwt_algorithm
        @jwt_algorithm ||= 'HS256'
      end

      # Set the signature key algorithm
      #
      # @param value [String], signature key algorithm
      #
      # @return [String], signature key algorithm
      def self.jwt_algorithm=(value)
        @jwt_algorithm = value
      end

      # The lifetime of the token, defaults to 1 day
      #
      # @return [Integer], token expiry in seconds
      def self.jwt_lifetime
        @jwt_lifetime ||= 60 * 60 * 24
      end

      # Set the lifetime of the token
      #
      # @param value [Integer], token expiry in seconds
      #
      # @return [Integer], token expiry in seconds
      def self.jwt_lifetime=(value)
        @jwt_lifetime = value
      end

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
