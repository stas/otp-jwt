require 'spec_helper'

RSpec.describe User, type: :model do
  let(:user) { create_user }

  it { expect(User.new.otp_secret).not_to be_blank }
  it { expect(User.new.deliver_otp).to be_blank }
  it { expect(User.new.otp).to be_blank }

  describe '#from_jwt' do
    let(:token) { user.to_jwt }

    it do
      expect(User.from_jwt(token)).to eq(user)
    end

    context 'with a cast-able subject value' do
      let(:token) { OTP::JWT::Token.sign(sub: user.id.to_s + '_text') }

      it do
        expect(User.from_jwt(token)).to be_nil
      end
    end

    context 'with a custom claim name' do
      let(:claim_value) { FFaker::Internet.password }
      let(:token) { user.to_jwt(my_claim_name: claim_value) }

      it do
        expect(OTP::JWT::Token.decode(token)['my_claim_name'])
          .to eq(claim_value)
        expect(User.from_jwt(token, 'my_claim_name')).to be_nil
      end
    end
  end

  describe '#otp' do
    it do
      expect { user.otp }.to change(user, :otp_counter).by(1)
    end

    context 'without a secret' do
      it do
        user.update_column(:otp_secret, nil)
        expect(user.otp).to be_nil
      end
    end
  end

  describe '#verify_otp' do
    it 'increments the otp counter after verification' do
      expect(user.verify_otp(user.otp)).to be_truthy
      expect { user.verify_otp(user.otp) }.to change(user, :otp_counter).by(2)
    end

    context 'without a secret' do
      it do
        user.update_column(:otp_secret, nil)
        expect(user.verify_otp(rand(1000..2000).to_s)).to be_nil
      end
    end
  end
end
