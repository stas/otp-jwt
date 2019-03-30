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
  end

  context 'with bad subject' do
    let(:user) { FFaker::Internet.password }

    it { expect(response).to have_http_status(:unauthorized) }
  end
end
