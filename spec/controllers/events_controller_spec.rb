# spec/controllers/events_controller_spec.rb

require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  let(:admin) { create(:user, admin: true) }
  let(:user) { create(:user, admin: false) }
  let!(:event) { create(:event, admin: admin) }

  # --- Tests pour un utilisateur non connecté ---
  describe "Guest access" do
    it "redirects to sign in for protected actions" do
      post :create, params: { event: { title: "New Event" } }
      expect(response).to redirect_to(new_user_session_path)

      get :edit, params: { id: event.id }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "allows access to public actions" do
      get :index
      expect(response).to be_successful

      get :show, params: { id: event.id }
      expect(response).to be_successful
    end
  end

  # --- Tests pour un utilisateur connecté mais non-admin ---
  describe "Authenticated user access" do
    before { sign_in user }

    it "redirects to root with an alert for admin-only actions" do
      get :new
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Accès réservé aux administrateurs.")

      post :create, params: { event: { title: "New Event" } }
      expect(response).to redirect_to(root_path)

      delete :destroy, params: { id: event.id }
      expect(response).to redirect_to(root_path)
    end
  end

  # --- Tests pour un administrateur ---
  describe "Admin access" do
    before { sign_in admin }

    describe "GET #new" do
      it "returns a success response" do
        get :new
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns a success response" do
        get :edit, params: { id: event.id }
        expect(response).to be_successful
      end
    end

    describe "POST #create" do
      context "with valid parameters" do
        let(:valid_attributes) { { title: "Portes Ouvertes", description: "Venez nous voir", start_date: Time.now, price: 0 } }

        it "creates a new event" do
          expect {
            post :create, params: { event: valid_attributes }
          }.to change(Event, :count).by(1)
        end

        it "redirects to the root path with a notice" do
          post :create, params: { event: valid_attributes }
          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to eq("L'événement a été créé avec succès.")
        end
      end

      context "with invalid parameters" do
        it "does not create a new event and re-renders the new template" do
          expect {
            post :create, params: { event: { title: "" } } # Titre manquant
          }.not_to change(Event, :count)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:new)
        end
      end
    end

    describe "PATCH #update" do
      context "with valid parameters" do
        let(:new_attributes) { { title: "Titre Mis à Jour" } }

        it "updates the requested event" do
          patch :update, params: { id: event.id, event: new_attributes }
          event.reload
          expect(event.title).to eq("Titre Mis à Jour")
        end

        it "redirects to the root path" do
          patch :update, params: { id: event.id, event: new_attributes }
          expect(response).to redirect_to(root_path)
        end
      end

      context "with invalid parameters" do
        it "renders the edit template" do
          patch :update, params: { id: event.id, event: { title: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:edit)
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the event and redirects" do
        # On s'assure que l'événement existe avant de le supprimer
        expect(Event.find(event.id)).to be_present
        
        expect {
          delete :destroy, params: { id: event.id }
        }.to change(Event, :count).by(-1)
        
        expect(response).to redirect_to(events_path)
        expect(flash[:notice]).to eq("L'événement a été supprimé avec succès.")
      end
    end
  end
end
