# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ComptaReportController, type: :controller do
  render_views false

  let(:admin) { create(:user, admin: true) }
  let(:tresorier) { create(:user, :tresorier) }
  let(:user) { create(:user, :pilote) }

  # Mock de TreasuryManager pour éviter les dépendances complexes
  before do
    # On suppose que la classe TreasuryManager existe, sinon on stub la constante
    # On définit une classe qui accepte des arguments pour initialize
    stub_const('TreasuryManager', Class.new do
      def initialize(_balance = nil); end
      def add_transaction(*); end
      def generate_report = {}
      def current_balance = 1000.0
    end)
    # Empêche Rails de chercher le template par défaut (implicit render)
    allow(controller).to receive(:default_render) { controller.head :ok }
  end

  describe 'GET #treasury_report' do
    context "en tant qu'admin" do
      before { sign_in admin }
      it 'répond avec succès' do
        get :treasury_report
        expect(response).to be_successful
      end
    end

    context 'en tant que trésorier' do
      before { sign_in tresorier }
      it 'répond avec succès' do
        get :treasury_report
        expect(response).to be_successful
      end
    end

    context "en tant qu'utilisateur lambda" do
      before { sign_in user }
      it 'redirige vers la racine' do
        get :treasury_report
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('pas les droits')
      end
    end
  end

  describe 'GET #yearly_accounting_report' do
    before { sign_in admin }

    it "répond avec succès pour l'année en cours" do
      get :yearly_accounting_report
      expect(response).to be_successful
    end

    it 'génère un PDF' do
      get :yearly_accounting_report, params: { year: Date.today.year, format: :pdf }
      expect(response).to be_successful
    end
  end
end
