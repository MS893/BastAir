require 'rails_helper'

RSpec.describe Admin::ComptaReportController, type: :controller do
  let(:admin) { create(:user, admin: true) }
  let(:tresorier) { create(:user, fonction: 'tresorier') }
  let(:user) { create(:user, fonction: 'pilote') }

  # Mock de TreasuryManager pour éviter les dépendances complexes
  let(:treasury_manager_double) { double("TreasuryManager", add_transaction: nil, generate_report: {}, current_balance: 1000.0) }

  before do
    # On suppose que la classe TreasuryManager existe, sinon on stub la constante
    stub_const("TreasuryManager", Class.new) unless defined?(TreasuryManager)
    allow(TreasuryManager).to receive(:new).and_return(treasury_manager_double)
  end

  describe "GET #treasury_report" do
    context "en tant qu'admin" do
      before { sign_in admin }
      it "répond avec succès" do
        get :treasury_report
        expect(response).to be_successful
      end
    end

    context "en tant que trésorier" do
      before { sign_in tresorier }
      it "répond avec succès" do
        get :treasury_report
        expect(response).to be_successful
      end
    end

    context "en tant qu'utilisateur lambda" do
      before { sign_in user }
      it "redirige vers la racine" do
        get :treasury_report
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("pas les droits")
      end
    end
  end

  describe "GET #yearly_accounting_report" do
    before { sign_in admin }

    it "répond avec succès pour l'année en cours" do
      get :yearly_accounting_report
      expect(response).to be_successful
    end

    it "génère un PDF" do
      get :yearly_accounting_report, params: { year: Date.today.year, format: :pdf }
      expect(response.content_type).to eq('application/pdf')
    end
  end
end