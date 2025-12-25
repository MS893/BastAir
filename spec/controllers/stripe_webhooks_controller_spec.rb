require 'rails_helper'

RSpec.describe StripeWebhooksController, type: :controller do
  let(:user) { create(:user) }
  let(:payload) { { id: 'evt_test', type: 'checkout.session.completed' }.to_json }
  
  # Mock de l'objet session Stripe
  let(:session_mock) do
    double(
      id: 'cs_test',
      payment_status: 'paid',
      amount_total: 10200, # 102.00 EUR
      metadata: double(user_id: user.id, intended_base_amount: 100.0)
    )
  end

  # Mock de l'objet line_item
  let(:line_item_mock) { double(description: "Montant choisi pour créditer mon compte BastAir") }
  let(:session_with_items) { double(line_items: double(data: [line_item_mock])) }

  before do
    # On mocke la construction de l'événement Stripe
    allow(Stripe::Webhook).to receive(:construct_event).and_return(
      double(type: 'checkout.session.completed', data: double(object: session_mock))
    )
    # On mocke la récupération de la session pour les line_items
    allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(session_with_items)
    
    # On s'assure que la clé secrète est présente (mock ou config)
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :webhooks_secret).and_return('whsec_test')
  end

  describe "POST #create" do
    it "credits the user account on successful payment" do
      expect {
        post :create, body: payload
      }.to change { user.reload.solde }.by(100.0) # 102€ payés - 2€ frais = 100€ crédités
      
      expect(response).to have_http_status(:ok)
    end

    it "handles errors gracefully" do
      allow(Stripe::Webhook).to receive(:construct_event).and_raise(JSON::ParserError)
      post :create, body: "invalid payload"
      expect(response).to have_http_status(400)
    end
  end
  
end
