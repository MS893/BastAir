# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ReservationsController, type: :controller do
  let(:admin) { create(:user, admin: true) }
  let(:reservation) { create(:reservation) }
  let(:calendar_service) { instance_double('GoogleCalendarService') }

  before do
    sign_in admin
    # Mock du service Google Calendar
    allow(GoogleCalendarService).to receive(:new).and_return(calendar_service)
    allow(calendar_service).to receive(:delete_event_for_app)
    allow(calendar_service).to receive(:delete_instructor_event)
  end

  describe 'GET #index' do
    it 'répond avec succès' do
      get :index
      expect(response).to be_successful
    end

    it 'filtre par utilisateur' do
      other_reservation = create(:reservation)
      get :index, params: { user_id: reservation.user_id }
      expect(assigns(:reservations)).to include(reservation)
      expect(assigns(:reservations)).not_to include(other_reservation)
    end
  end

  describe 'DELETE #destroy' do
    it 'supprime la réservation et appelle le service calendrier' do
      expect(calendar_service).to receive(:delete_event_for_app).with(reservation)

      expect do
        delete :destroy, params: { id: reservation.id }
      end.to change(Reservation, :count).by(-1)

      expect(response).to redirect_to(admin_reservations_path)
    end

    it 'gère les requêtes Turbo Stream' do
      delete :destroy, params: { id: reservation.id }, format: :turbo_stream
      expect(response.media_type).to eq Mime[:turbo_stream]
    end
  end
end
