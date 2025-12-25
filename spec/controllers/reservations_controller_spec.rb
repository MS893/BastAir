# spec/controllers/reservations_controller_spec.rb

require 'rails_helper'

RSpec.describe ReservationsController, type: :controller do
  # On crée un utilisateur avec un solde positif et des dates valides par défaut
  let(:valid_user) { create(:user, solde: 100, date_licence: Date.today + 1.year, medical: Date.today + 1.year, controle: Date.today + 1.year) }
  let(:avion) { create(:avion) }

  # Mock du service Google Calendar pour éviter les appels API réels
  let(:calendar_service) { instance_double("GoogleCalendarService") }

  before do
    allow(GoogleCalendarService).to receive(:new).and_return(calendar_service)
    allow(calendar_service).to receive(:create_event_for_app)
    allow(calendar_service).to receive(:update_event_for_app)
    allow(calendar_service).to receive(:delete_event_for_app)
    allow(calendar_service).to receive(:create_instructor_event_only)
    allow(calendar_service).to receive(:delete_instructor_event)
    allow(calendar_service).to receive(:delete_instructor_event_by_id)
  end

  describe "Authenticated user access" do
    context "with a valid user" do
      before { sign_in valid_user }

      it "allows access to the new action" do
        get :new
        expect(response).to be_successful
        expect(response).to render_template(:new)
      end

      it "creates a reservation with valid params" do
        start_t = Time.zone.now.tomorrow.change(hour: 10, min: 0, sec: 0)
        reservation_params = {
          avion_id: avion.id,
          start_time: start_t,
          end_time: start_t + 2.hours,
          type_vol: "solo"
        }
        expect {
          post :create, params: { reservation: reservation_params }
        }.to change(Reservation, :count).by(1)
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq('Votre réservation a été créée avec succès.')
      end

      it "calls create_event_for_app on GoogleCalendarService" do
        start_t = Time.zone.now.tomorrow.change(hour: 10, min: 0, sec: 0)
        reservation_params = {
          avion_id: avion.id,
          start_time: start_t,
          end_time: start_t + 2.hours,
          type_vol: "solo"
        }

        expect(calendar_service).to receive(:create_event_for_app)

        post :create, params: { reservation: reservation_params }
      end

      it "sends a confirmation email" do
        start_t = Time.zone.now.tomorrow.change(hour: 10, min: 0, sec: 0)
        reservation_params = {
          avion_id: avion.id,
          start_time: start_t,
          end_time: start_t + 2.hours,
          type_vol: "solo"
        }

        expect {
          post :create, params: { reservation: reservation_params }
        }.to have_enqueued_mail(UserMailer)
      end

      it "does not create a reservation with invalid params and re-renders new" do
        # Test avec une date de fin antérieure à la date de début
        start_t = Time.zone.now.tomorrow.change(hour: 10, min: 0, sec: 0)
        invalid_params = {
          avion_id: avion.id,
          start_time: start_t,
          end_time: start_t - 2.hours,
          type_vol: "solo"
        }
        expect {
          post :create, params: { reservation: invalid_params }
        }.not_to change(Reservation, :count)
        expect(response).to render_template(:new)
      end

      describe "DELETE #destroy" do
        # On fixe une date/heure valide (demain à 10h) pour éviter les erreurs de validation (7h-17h)
        # Pour le test de pénalité < 12h, on doit être proche du vol.
        # On simule qu'on est le jour même à 8h00, pour un vol à 10h00.
        
        let(:start_t) { Time.zone.now.change(hour: 10, min: 0, sec: 0) }
        let(:end_t) { start_t + 2.hours }
        
        let!(:reservation_to_delete) { create(:reservation, user: valid_user, avion: avion, start_time: start_t, end_time: end_t) }

        before do
          # Mock des paramètres de pénalité pour simuler une annulation tardive
          # Seuil 1 : < 12h => 20€
          # Seuil 2 : < 24h => 10€
          
          # On voyage dans le temps à 8h00 le jour du vol (2h avant)
          travel_to(start_t - 2.hours)

          allow(Rails.cache).to receive(:fetch).with('penalty_settings', anything).and_return([
            { delay: 12, amount: 20 },
            { delay: 24, amount: 10 }
          ])
        end

        after { travel_back }

        it "destroys the reservation" do
          expect {
            delete :destroy, params: { id: reservation_to_delete.id, cancellation_reason: "Imprévu" }
          }.to change(Reservation, :count).by(-1)
        end

        it "creates a penalty when cancellation is late (within 12h)" do
          expect {
            delete :destroy, params: { id: reservation_to_delete.id, cancellation_reason: "Malade" }
          }.to change(Penalite, :count).by(1)

          penalty = Penalite.last
          expect(penalty.penalty_amount).to eq(20)
          expect(penalty.cancellation_reason).to eq("Malade")
          expect(penalty.user).to eq(valid_user)
        end

        it "calls delete_event_for_app on GoogleCalendarService" do
          expect(calendar_service).to receive(:delete_event_for_app)
          delete :destroy, params: { id: reservation_to_delete.id, cancellation_reason: "Test" }
        end

        it "does not call delete_instructor_event for standard flights" do
          expect(calendar_service).not_to receive(:delete_instructor_event)
          delete :destroy, params: { id: reservation_to_delete.id, cancellation_reason: "Test" }
        end

        context "when deleting an instruction flight" do
          let(:instructor) { create(:user, :instructeur) }
          let!(:instruction_reservation) do
            r = build(:reservation, user: valid_user, avion: avion, instruction: true, fi: instructor.name, start_time: start_t + 1.day, end_time: end_t + 1.day)
            # On mocke la méthode de validation pour éviter de devoir créer les disponibilités
            allow(r).to receive(:instructor_is_available)
            r.save!
            r
          end

          it "calls delete_instructor_event and delete_event_for_app on GoogleCalendarService" do
            expect(calendar_service).to receive(:delete_instructor_event).with(instruction_reservation)
            expect(calendar_service).to receive(:delete_event_for_app).with(instruction_reservation)
            delete :destroy, params: { id: instruction_reservation.id, cancellation_reason: "Annulation cours" }
          end
        end

        it "does not create a penalty when cancellation is early enough" do
          early_reservation = create(:reservation, user: valid_user, avion: avion, start_time: start_t + 48.hours, end_time: end_t + 48.hours)
          
          expect {
            delete :destroy, params: { id: early_reservation.id, cancellation_reason: "Vacances" }
          }.not_to change(Penalite, :count)
        end

        it "does not debit the user immediately (penalty status is 'En attente')" do
          # Le solde ne doit pas bouger car la pénalité est créée en statut "En attente"
          expect {
            delete :destroy, params: { id: reservation_to_delete.id, cancellation_reason: "Malade" }
          }.not_to change { valid_user.reload.solde }
        end
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
