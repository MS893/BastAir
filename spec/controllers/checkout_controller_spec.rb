require 'rails_helper'

RSpec.describe CheckoutController, type: :controller do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "POST #create" do
    it "redirects to stripe session url" do
      # Mock Stripe Session creation
      session_mock = double(url: 'https://checkout.stripe.com/test')
      expect(Stripe::Checkout::Session).to receive(:create).and_return(session_mock)

      post :create, params: { amount: 100, description: "Crédit" }
      expect(response).to redirect_to('https://checkout.stripe.com/test')
    end

    it "validates amount for custom credit" do
      post :create, params: { amount: 0, description: "Montant choisi pour créditer mon compte BastAir" }
      expect(response).to redirect_to(credit_path)
      expect(flash[:alert]).to eq("Montant incorrect")
    end
  end
  
end
