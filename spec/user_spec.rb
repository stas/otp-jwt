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
  end

  describe '#otp' do
    it do
      expect { user.otp }.to change(user, :otp_counter).by(1)
    end
  end

  describe '#verify_otp' do
    it 'increments the otp counter after verification' do
      expect(user.verify_otp(user.otp)).to be_truthy
      expect { user.verify_otp(user.otp) }.to change(user, :otp_counter).by(2)
    end
  end

  describe '#verify_otp' do
    it 'increments the otp counter after verification' do
      expect(user.verify_otp(user.otp)).to be_truthy
      expect { user.verify_otp(user.otp) }.to change(user, :otp_counter).by(2)
    end
  end
end
