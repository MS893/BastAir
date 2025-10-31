# spec/controllers/reservations_controller_spec.rb

require 'rails_helper'

RSpec.describe ReservationsController, type: :controller do
  # On crée un utilisateur avec un solde positif et des dates valides par défaut
  let(:valid_user) { create(:user, solde: 100, date_licence: Date.today + 1.year, medical: Date.today + 1.year, controle: Date.today + 1.year) }
  let(:avion) { create(:avion) }

  describe "Authenticated user access" do
    context "with a valid user" do
      before { sign_in valid_user }

      it "allows access to the new action" do
        get :new
        expect(response).to be_successful
        expect(response).to render_template(:new)
      end

      it "creates a reservation with valid params" do
        reservation_params = {
          avion_id: avion.id,
          date_debut: Time.now + 1.day,
          date_fin: Time.now + 1.day + 2.hours,
          type_vol: "solo"
        }
        expect {
          post :create, params: { reservation: reservation_params }
        }.to change(Reservation, :count).by(1)
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq('Votre réservation a été créée avec succès.')
      end
    end

    context "with a user having a negative balance" do
      let(:user_with_negative_balance) { create(:user, solde: -50) }
      before { sign_in user_with_negative_balance }

      it "redirects from 'new' to the credit page" do
        get :new
        expect(response).to redirect_to(credit_path)
        expect(flash[:alert]).to eq("Votre solde est négatif ou nul. Veuillez créditer votre compte avant de pouvoir réserver un vol.")
      end
    end

    context "with a user having an expired license" do
      let(:user_with_expired_license) { create(:user, solde: 100, date_licence: Date.today - 1.day, medical: Date.today + 1.year) }
      before { sign_in user_with_expired_license }

      it "redirects from 'new' to the root path with an alert" do
        get :new
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("votre licence a expiré.")
      end
    end
  end
end
