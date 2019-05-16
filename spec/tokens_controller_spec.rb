require 'spec_helper'

RSpec.describe TokensController, type: :request do
  let(:user) { create_user }
  let(:params) { }

  around do |examp|
    perform_enqueued_jobs(&examp)
  end

  before do
    ActionMailer::Base.deliveries.clear
    ActiveJob::Base.queue_adapter.performed_jobs.clear
    post(tokens_path, params: params.to_json, headers: json_headers)
  end

  it { expect(response).to have_http_status(:forbidden) }

  context 'with good email and no otp' do
    let(:params) { { email: user.email } }

    it do
      expect(response).to have_http_status(:bad_request)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq(OTP::Mailer.default[:subject])
    end
  end

  context 'with good email and bad otp' do
    let(:params) { { email: user.email, otp: FFaker::Internet.password } }

    it do
      expect(response).to have_http_status(:forbidden)
      expect(ActionMailer::Base.deliveries.size).to eq(0)
    end
  end

  context 'with good email and good otp' do
    let(:params) { { email: user.email, otp: user.otp } }

    it do
      expect(response).to have_http_status(:created)
      expect(User.from_jwt(response_json['token'])).to eq(user)
      expect(ActionMailer::Base.deliveries.size).to eq(0)

      expect(user.reload.last_login_at).not_to be_blank
    end
  end
end
