require 'rails_helper'

RSpec.describe AvionsController, type: :controller do
  let(:user) { create(:user, :pilote) }
  let(:avion) { create(:avion) }

  # Authentification avant chaque test car le contrôleur utilise authenticate_user!
  before { sign_in user }

  describe "GET #last_compteur" do
    context "quand des vols existent pour l'avion" do
      # On crée des vols avec des compteurs différents
      # Note: On suppose que la factory :vol gère les associations nécessaires (user, avion)
      let!(:vol_ancien) { create(:vol, avion: avion, user: user, compteur_depart: 900, compteur_arrivee: 1000) }
      let!(:vol_recent) { create(:vol, avion: avion, user: user, compteur_depart: 1000, compteur_arrivee: 1050) }

      it "renvoie la valeur du compteur d'arrivée du dernier vol (le plus élevé)" do
        get :last_compteur, params: { id: avion.id }
        
        expect(response).to be_successful
        expect(response.content_type).to include('application/json')
        
        json_response = JSON.parse(response.body)
        # Le contrôleur cherche le vol avec le plus grand compteur_arrivee
        expect(json_response['compteur_depart']).to eq(1050)
      end
    end

    context "quand aucun vol n'existe pour l'avion" do
      it "renvoie une chaîne vide" do
        get :last_compteur, params: { id: avion.id }
        
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['compteur_depart']).to eq('')
      end
    end
  end

  describe "GET #signalements_list" do
    # Création de signalements avec différents statuts
    # Assurez-vous que votre factory :signalement existe
    let!(:signalement_ouvert) { create(:signalement, avion: avion, user: user, status: 'En cours') }
    let!(:signalement_resolu) { create(:signalement, avion: avion, user: user, status: 'Résolu') }

    it "assigne @avion" do
      get :signalements_list, params: { id: avion.id }
      expect(assigns(:avion)).to eq(avion)
    end

    it "récupère uniquement les signalements non résolus" do
      get :signalements_list, params: { id: avion.id }
      expect(assigns(:signalements)).to include(signalement_ouvert)
      expect(assigns(:signalements)).not_to include(signalement_resolu)
    end

    context "sans le paramètre source (cas par défaut)" do
      it "rend le partial show_for_reservation" do
        get :signalements_list, params: { id: avion.id }
        expect(response).to render_template('signalements/_show_for_reservation')
      end
    end

    context "avec source='modal'" do
      it "rend le partial list_for_modal" do
        get :signalements_list, params: { id: avion.id, source: 'modal' }
        expect(response).to render_template('signalements/_list_for_modal')
      end
    end
  end
end