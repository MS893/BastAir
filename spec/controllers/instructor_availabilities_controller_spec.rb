# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InstructorAvailabilitiesController, type: :controller do
  let(:instructor) { create(:user, :instructeur) }
  let(:user) { create(:user) }

  describe 'GET #edit' do
    context 'as instructor' do
      before { sign_in instructor }
      it 'returns success' do
        get :edit
        expect(response).to be_successful
      end
    end

    context 'as normal user' do
      before { sign_in user }
      it 'returns unauthorized json' do
        get :edit
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
