require 'rails_helper'

RSpec.describe TransactionsController, type: :controller do
  # On prépare les différents types d'utilisateurs et une transaction de test
  let(:admin) { create(:user, admin: true) }
  let(:tresorier) { create(:user, :tresorier) }
  let(:pilote) { create(:user, :pilote) }
  let!(:transaction) { create(:transaction) }

  # Attributs valides pour créer/mettre à jour une transaction
  let(:valid_attributes) do
    {
      date_transaction: Date.today,
      description: "Achat de carburant",
      mouvement: 'Dépense',
      montant: 150.50,
      source_transaction: 'Charges Exceptionnelles',
      payment_method: 'Virement',
      user_id: tresorier.id
    }
  end

  # Attributs invalides (montant manquant)
  let(:invalid_attributes) do
    {
      description: "Transaction incomplète",
      montant: nil
    }
  end

  # --- Tests pour un utilisateur non connecté ---
  describe "Guest access" do
    it "redirects to the sign-in page for all actions" do
      get :index
      expect(response).to redirect_to(new_user_session_path)

      get :show, params: { id: transaction.id }
      expect(response).to redirect_to(new_user_session_path)

      post :create, params: { transaction: valid_attributes }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  # --- Tests pour un utilisateur connecté mais non autorisé (ex: un pilote) ---
  describe "Unauthorized user access" do
    before { sign_in pilote }

    it "redirects to the root path with an alert" do
      get :index
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("Accès réservé")
    end
  end

  # --- Tests pour un utilisateur autorisé (Trésorier) ---
  # On ne teste que le trésorier, car le comportement pour l'admin est identique.
  describe "Authorized access (Treasurer)" do
    before { sign_in tresorier }

    describe "GET #index" do
      it "is successful and renders the index template" do
        get :index
        expect(response).to be_successful
        expect(response).to render_template(:index)
        expect(assigns(:transactions)).to include(transaction)
      end
    end

    describe "GET #show" do
      it "is successful and assigns the correct transaction" do
        get :show, params: { id: transaction.id }
        expect(response).to be_successful
        expect(assigns(:transaction)).to eq(transaction)
      end
    end

    describe "GET #new" do
      it "is successful and assigns a new transaction" do
        get :new
        expect(response).to be_successful
        expect(assigns(:transaction)).to be_a_new(Transaction)
      end
    end

    describe "POST #create" do
      context "with valid parameters" do
        it "creates a new Transaction" do
          expect {
            post :create, params: { transaction: valid_attributes }
          }.to change(Transaction, :count).by(1)
        end

        it "redirects to the created transaction with a notice" do
          post :create, params: { transaction: valid_attributes }
          expect(response).to redirect_to(Transaction.last)
          expect(flash[:notice]).to eq('La transaction a été créée avec succès.')
        end
      end

      context "with invalid parameters" do
        it "does not create a new Transaction and re-renders the 'new' template" do
          expect {
            post :create, params: { transaction: invalid_attributes }
          }.not_to change(Transaction, :count)
          expect(response).to have_http_status(:unprocessable_content)
          expect(response).to render_template(:new)
        end
      end
    end

    describe "PATCH #update" do
      context "with valid parameters" do
        let(:new_attributes) { { description: "Nouvelle description" } }

        it "updates the requested transaction" do
          patch :update, params: { id: transaction.id, transaction: new_attributes }
          transaction.reload
          expect(transaction.description).to eq("Nouvelle description")
        end

        it "redirects to the transaction with a notice" do
          patch :update, params: { id: transaction.id, transaction: new_attributes }
          expect(response).to redirect_to(transaction)
          expect(flash[:notice]).to eq('La transaction a été mise à jour avec succès.')
        end
      end

      context "with invalid parameters" do
        it "does not update the transaction and re-renders the 'edit' template" do
          patch :update, params: { id: transaction.id, transaction: invalid_attributes }
          transaction.reload
          expect(transaction.montant).not_to be_nil # Vérifie que la valeur n'a pas été écrasée
          expect(response).to have_http_status(:unprocessable_content)
          expect(response).to render_template(:edit)
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested transaction" do
        expect {
          delete :destroy, params: { id: transaction.id }
        }.to change(Transaction, :count).by(-1)
      end

      it "redirects to the transactions list with a notice" do
        delete :destroy, params: { id: transaction.id }
        expect(response).to redirect_to(transactions_url)
        expect(flash[:notice]).to eq('La transaction a été supprimée avec succès.')
      end
    end
  end
end
