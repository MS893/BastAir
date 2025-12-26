# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:user, admin: true) }
  let(:other_user) { create(:user) }

  describe 'GET #index' do
    context 'as admin' do
      before { sign_in admin }
      it 'returns success' do
        get :index
        expect(response).to be_successful
      end
    end

    context 'as normal user' do
      before { sign_in user }
      it 'redirects to root' do
        get :index
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET #show' do
    before { sign_in user }

    it 'shows own profile' do
      get :show, params: { id: user.id }
      expect(response).to be_successful
    end

    it 'redirects when trying to view other profile' do
      get :show, params: { id: other_user.id }
      expect(response).to redirect_to(root_path)
    end

    context 'as admin' do
      before { sign_in admin }
      it 'shows any profile' do
        get :show, params: { id: other_user.id }
        expect(response).to be_successful
      end
    end
  end

  describe 'GET #vols' do
    let(:pilot_user) { create(:user, :pilote) }
    before { sign_in pilot_user }
    let!(:vol) { create(:vol, user: pilot_user, instructeur: nil) }

    it 'returns success' do
      get :vols, params: { id: pilot_user.id }
      expect(response).to be_successful
    end

    it 'exports CSV' do
      get :vols, params: { id: pilot_user.id, start_date: Time.zone.today - 1.month, end_date: Time.zone.today, format: :csv }
      expect(response.header['Content-Type']).to include 'text/csv'
    end
  end

  describe 'PATCH #update' do
    before { sign_in admin }

    it 'updates user roles' do
      instructeur_val = User::ALLOWED_FCT.values.find { |v| v != user.fonction } || User::ALLOWED_FCT.values.last
      patch :update, params: { id: user.id, user: { fonction: instructeur_val } }
      user.reload
      expect(user.fonction).to eq(instructeur_val)
      expect(response).to redirect_to(users_path)
    end
  end

  describe 'PATCH #update_profil' do
    before { sign_in user }

    it 'updates profile info' do
      patch :update_profil, params: { id: user.id, user: { telephone: '0600000000' } }
      user.reload
      expect(user.telephone).to eq('0600000000')
      expect(response).to redirect_to(user_path(user))
    end
  end
end
