require 'rails_helper'

RSpec.describe VolsController, type: :controller do
  # Définition des utilisateurs
  let(:user) { create(:user, :pilote) }
  let(:admin) { create(:user, admin: true) }
  let(:instructeur) { create(:user, :instructeur) }
  
  # Définition des données nécessaires
  let(:avion) { create(:avion) }
  # On suppose qu'une factory 'tarif' existe, sinon on crée un objet Tarif manuellement si nécessaire
  let!(:tarif) { create(:tarif) rescue Tarif.create(annee: 2024, tarif_horaire_avion1: 150) }
  let!(:vol) { create(:vol, user: user, avion: avion, instructeur: nil, debut_vol: Date.yesterday.to_time + 10.hours) }

  describe "GET #index" do
    context "when user is signed in" do
      before { sign_in user }

      it "returns a success response" do
        get :index
        expect(response).to be_successful
      end

      it "assigns @vols" do
        get :index
        expect(assigns(:vols)).to include(vol)
      end

      it "exports CSV" do
        get :index, format: :csv
        expect(response.header['Content-Type']).to include 'text/csv'
      end
    end

    context "when user is not signed in" do
      it "redirects to sign in" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET #new" do
    context "when user is signed in" do
      before { sign_in user }

      it "returns a success response" do
        get :new
        expect(response).to be_successful
      end

      it "assigns a new Vol" do
        get :new
        expect(assigns(:vol)).to be_a_new(Vol)
      end

      it "assigns instance variables" do
        get :new
        expect(assigns(:avions)).to include(avion)
        expect(assigns(:tarif)).to be_present
      end
    end
  end

  describe "POST #create" do
    before { sign_in user }

    let(:valid_attributes) do
      {
        avion_id: avion.id,
        debut_vol_date: Date.today.to_s,
        debut_vol_hour: "10",
        debut_vol_minute: "00",
        duree_vol: 1.5,
        fin_vol: "#{Date.today} 11:30:00",
        compteur_depart: 1001.0,
        compteur_arrivee: 1002.5,
        depart: "LFPT",
        arrivee: "LFPT",
        type_vol: "Standard",
        solo: true,
        nb_atterro: 1
      }
    end

    let(:invalid_attributes) do
      { avion_id: nil }
    end

    context "with valid params" do
      it "creates a new Vol" do
        expect {
          post :create, params: { vol: valid_attributes }
        }.to change(Vol, :count).by(1)
      end

      it "redirects to the root path" do
        post :create, params: { vol: valid_attributes }
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq('Votre vol a été enregistré avec succès.')
      end

      it "sends a landing tax email if tax is declared" do
        create(:user, admin: true, email: "admin@example.com")
        expect(UserMailer).to receive(:landing_tax_notification).and_return(double(deliver_later: true))

        post :create, params: { 
          vol: valid_attributes.merge(taxe_atterrissage: "Taxe non payée"),
          taxe_aerodrome: "LFPB"
        }
      end
    end

    context "with invalid params" do
      it "does not create a new Vol and re-renders new" do
        expect {
          post :create, params: { vol: invalid_attributes }
        }.not_to change(Vol, :count)
        expect(response).to have_http_status(::unprocessable_content)
        expect(response).to render_template(:new)
      end
    end
  end

  describe "PATCH #update" do
    let(:eleve) { create(:user, :eleve) }
    let(:vol_eleve) { create(:vol, user: eleve) }

    context "as an authorized user (Instructor)" do
      before { sign_in instructeur }

      it "updates the vol and redirects to progression" do
        patch :update, params: { id: vol_eleve.id, comment: "Test comment", status: "1" }
        expect(response).to redirect_to(livret_progression_path(eleve_id: eleve.id))
        expect(flash[:notice]).to eq("Vol validé et leçon mise à jour.")
      end

      it "requires a comment" do
        patch :update, params: { id: vol_eleve.id, comment: "" }
        expect(response).to redirect_to(livret_progression_path(eleve_id: eleve.id))
        expect(flash[:alert]).to include("Le commentaire est obligatoire")
      end
    end

    context "as an unauthorized user (Student)" do
      before { sign_in user }

      it "redirects to root path" do
        patch :update, params: { id: vol.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Vous n'êtes pas autorisé à effectuer cette action.")
      end
    end
  end
end