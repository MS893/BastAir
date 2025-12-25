require 'rails_helper'

RSpec.describe Admin::PenalitesController, type: :controller do
  let(:admin) { create(:user, admin: true) }
  let(:user) { create(:user) }
  let(:penalite) { create(:penalite, user: user, penalty_amount: 20, status: 'En attente') }

  before { sign_in admin }

  describe "PATCH #apply" do
    it "applique la pénalité et débite l'utilisateur" do
      expect {
        patch :apply, params: { id: penalite.id }
      }.to change(Transaction, :count).by(1)
      
      penalite.reload
      expect(penalite.status).to eq('Appliquée')
      expect(penalite.admin).to eq(admin)
      expect(flash[:notice]).to include("appliquée")
    end

    it "ne fait rien si déjà appliquée" do
      penalite.update(status: 'Appliquée')
      expect {
        patch :apply, params: { id: penalite.id }
      }.not_to change(Transaction, :count)
      expect(flash[:alert]).to include("déjà été appliquée")
    end
  end

  describe "PATCH #cancel" do
    context "quand la pénalité est appliquée" do
      before do
        penalite.update(status: 'Appliquée')
        # Créer la transaction associée pour pouvoir la supprimer
        Transaction.create!(user: user, montant: 20, mouvement: 'Dépense', description: "Pénalité pour annulation tardive du vol du #{I18n.l(penalite.reservation_start_time, format: :short_year_time)}", source_transaction: 'Charges Exceptionnelles', payment_method: 'Prélèvement sur compte', date_transaction: Date.today)
      end

      it "annule la pénalité et supprime la transaction" do
        expect {
          patch :cancel, params: { id: penalite.id }
        }.to change(Transaction, :count).by(-1)
        
        expect(penalite.reload.status).to eq('Annulée')
        expect(flash[:notice]).to include("annulée")
      end
    end

    context "quand la pénalité est en attente" do
      it "annule simplement la pénalité" do
        patch :cancel, params: { id: penalite.id }
        expect(penalite.reload.status).to eq('Annulée')
        expect(flash[:notice]).to include("annulée")
      end
    end
  end
end