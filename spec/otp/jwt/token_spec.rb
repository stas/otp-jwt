require 'spec_helper'

RSpec.describe OTP::JWT::Token, type: :model do
  let(:payload) { { 'sub' => FFaker::Internet.password } }
  let(:token) do
    JWT.encode(
      payload,
      described_class.jwt_signature_key,
      described_class.jwt_algorithm
    )
  end

  describe '#sign' do
    it { expect(described_class.sign(payload)).to eq(token) }
  end

  describe '#verify' do
    it { expect(described_class.verify(token).first).to eq(payload) }

    context 'with a bad token' do
      it do
        expect { described_class.verify(FFaker::Internet.password) }
          .to raise_error(JWT::DecodeError)
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
        expect(described_class.decode(token) { |p| nil }).to eq(nil)
      end
    end
  end
end
