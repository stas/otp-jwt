require 'spec_helper'

RSpec.describe OTP::JWT::Token, type: :model do
  let(:payload) { { 'sub' => FFaker::Internet.password } }
  let(:token) do
    JWT.encode(
      payload.dup.merge(exp: Time.now.to_i + described_class.jwt_lifetime),
      described_class.jwt_signature_key,
      described_class.jwt_algorithm
    )
  end

  describe '#sign' do
    it { expect(described_class.sign(payload)).to eq(token) }

    context 'with the none algorithm' do
      before do
        OTP::JWT::Token.jwt_algorithm = 'none'
      end

      after do
        OTP::JWT::Token.jwt_algorithm = 'HS256'
      end

      it { expect(described_class.sign(payload)).to eq(token) }
    end
  end

  describe '#verify' do
    it do
      expect(described_class.verify(token).first).to include(payload)
    end

    it 'with a bad token' do
      expect { described_class.verify(FFaker::Internet.password) }
        .to raise_error(JWT::DecodeError)
    end

    it 'with an expired token' do
      token = OTP::JWT::Token.sign(
        sub: FFaker::Internet.password, exp: DateTime.now.to_i
      )
      expect { described_class.verify(token) }
        .to raise_error(JWT::ExpiredSignature)
    end

    context 'with an RSA key' do
      before do
        OTP::JWT::Token.jwt_signature_key = OpenSSL::PKey::RSA.new(2048)
        OTP::JWT::Token.jwt_algorithm = 'RS256'
      end

      after do
        OTP::JWT::Token.jwt_signature_key = '_'
        OTP::JWT::Token.jwt_algorithm = 'HS256'
      end

      it do
        expect(described_class.verify(token).first).to include(payload)
      end
    end
  end

  describe '#decode' do
    let(:user) { create_user }
    let(:payload) { { 'sub' => user.id } }

    it do
      expect(
        described_class.decode(token) { |p| User.find(p['sub']) }
      ).to eq(user)
    end

    context 'with a bad token' do
      let(:token) { FFaker::Internet.password }

      it do
        expect(described_class.decode(token)).to eq(nil)
      end
    end

    context 'with the none algorithm' do
      before do
        OTP::JWT::Token.jwt_algorithm = 'none'
      end

      after do
        OTP::JWT::Token.jwt_algorithm = 'HS256'
      end

      it do
        expect(
          described_class.decode(token) { |p| User.find(p['sub']) }
        ).to eq(user)
      end
    end
  end
end
