require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  let(:admin) { create(:user, admin: true) }

  before { sign_in admin }

  describe "GET #new" do
    it "répond avec succès" do
      get :new
      expect(response).to be_successful
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  describe "POST #create" do
    let(:valid_attributes) { attributes_for(:user).merge(email: "newuser@example.com", password: "password", password_confirmation: "password") }
    let(:invalid_attributes) { attributes_for(:user).merge(email: "") }

    context "avec des paramètres valides" do
      it "crée un nouvel utilisateur" do
        expect {
          post :create, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it "redirige vers le profil de l'utilisateur" do
        post :create, params: { user: valid_attributes }
        expect(response).to redirect_to(user_path(User.last))
      end
    end

    context "avec des paramètres invalides" do
      it "ne crée pas d'utilisateur et rend le template new" do
        expect {
          post :create, params: { user: invalid_attributes }
        }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
      end
    end
  end
end