require 'rails_helper'

RSpec.describe Admin::MaintenancesController, type: :controller do
  let(:admin) { create(:user, admin: true) }
  let(:user) { create(:user, admin: false) }
  let(:avion) { create(:avion) }

  before { sign_in admin }

  describe "GET #index" do
    it "répond avec succès" do
      get :index
      expect(response).to be_successful
    end

    it "assigne l'avion sélectionné si paramètre présent" do
      get :index, params: { avion_id: avion.id }
      expect(assigns(:selected_avion)).to eq(avion)
    end
  end

  describe "GET #show" do
    it "redirige vers l'index avec l'avion sélectionné" do
      get :show, params: { id: avion.id }
      expect(response).to redirect_to(admin_maintenances_path(avion_id: avion.id))
    end

    it "génère un PDF du dossier de maintenance" do
      get :show, params: { id: avion.id, format: :pdf }
      expect(response.content_type).to eq('application/pdf')
    end
  end

  describe "PATCH #update" do
    it "met à jour les attributs de l'avion et crée un log" do
      expect {
        patch :update, params: { id: avion.id, avion: { marque: "NouvelleMarque" } }
      }.to change(ActivityLog, :count).by(1)
      
      expect(avion.reload.marque).to eq("NouvelleMarque")
      expect(response).to redirect_to(admin_maintenances_path(avion_id: avion.id))
    end
  end

  describe "Actions de réinitialisation (Reset)" do
    it "réinitialise le potentiel 50h" do
      patch :reset_50h, params: { id: avion.id }
      expect(avion.reload.next_50h).to eq(50.0)
      expect(flash[:notice]).to include("50h réinitialisé")
    end

    it "réinitialise le potentiel 100h" do
      patch :reset_100h, params: { id: avion.id }
      expect(avion.reload.next_100h).to eq(100.0)
    end

    it "valide la visite annuelle" do
      patch :reset_annuelle, params: { id: avion.id }
      expect(avion.reload.annuelle).to eq(Date.today + 1.year)
    end
  end

  describe "POST #notify_grounded" do
    it "annule les réservations futures pour les avions indisponibles" do
      # On rend l'avion indisponible
      avion.update(potentiel_moteur: 0)
      # On crée une réservation future
      reservation = create(:reservation, avion: avion, start_time: Time.now + 2.days, end_time: Time.now + 2.days + 1.hour)
      
      post :notify_grounded
      
      expect(reservation.reload.status).to eq('cancelled')
      expect(flash[:notice]).to include("réservations ont été annulées")
    end
  end
end