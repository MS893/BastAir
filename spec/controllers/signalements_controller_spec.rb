require 'rails_helper'

RSpec.describe SignalementsController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:user, admin: true) }
  let(:avion) { create(:avion) }
  let(:signalement) { create(:signalement, user: user, avion: avion) }

  before { sign_in user }

  describe "GET #index" do
    it "returns success" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    let(:valid_attributes) { { description: "Problème radio" } }

    it "creates a new Signalement" do
      expect {
        post :create, params: { avion_id: avion.id, signalement: valid_attributes }
      }.to change(Signalement, :count).by(1)
    end

    it "sends notification emails" do
      expect(SignalementMailer).to receive(:new_signalement_notification).at_least(:once).and_return(double(deliver_later: true))
      post :create, params: { avion_id: avion.id, signalement: valid_attributes }
    end
  end

  describe "PATCH #update" do
    context "as admin" do
      before { sign_in admin }

      it "updates status" do
        patch :update, params: { id: signalement.id, signalement: { status: 'Résolu' } }
        signalement.reload
        expect(signalement.status).to eq('Résolu')
      end
    end

    context "as user" do
      it "redirects" do
        patch :update, params: { id: signalement.id, signalement: { status: 'Résolu' } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE #destroy" do
    before { sign_in admin }
    let!(:sig_to_delete) { create(:signalement, user: user, avion: avion) }

    it "destroys the signalement" do
      expect {
        delete :destroy, params: { id: sig_to_delete.id }
      }.to change(Signalement, :count).by(-1)
    end
  end

end
