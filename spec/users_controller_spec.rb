require 'spec_helper'

RSpec.describe UsersController, type: :request do
  let(:user) { nil }

  before do
    get(users_path, headers: jwt_auth_header(user))
  end

  it { expect(response).to have_http_status(:unauthorized) }

  context 'with known subject token' do
    let(:user) { create_user }

    it { expect(response).to have_http_status(:ok) }

    context 'with the expiration for JWT in future' do
      let(:user) { create_user(expire_jwt_at: DateTime.tomorrow) }

      it do
        expect(response).to have_http_status(:ok)
        expect(user.reload.expire_jwt_at).not_to be_nil
      end
    end

    context 'with the expiration past for JWT' do
      let(:user) { create_user(expire_jwt_at: DateTime.yesterday) }

      it do
        expect(response).to have_http_status(:unauthorized)
        expect(user.reload.expire_jwt_at).not_to be_nil
      end
    end
  end

  context 'with bad subject' do
    let(:user) { FFaker::Internet.password }

    it { expect(response).to have_http_status(:unauthorized) }
  end
end
