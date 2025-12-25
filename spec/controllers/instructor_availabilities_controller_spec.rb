require 'rails_helper'

RSpec.describe InstructorAvailabilitiesController, type: :controller do
  let(:instructor) { create(:user, fonction: 'instructeur', fi: Date.today + 1.year) }
  let(:user) { create(:user) }

  describe "GET #edit" do
    context "as instructor" do
      before { sign_in instructor }
      it "returns success" do
        get :edit
        expect(response).to be_successful
      end
    end

    context "as normal user" do
      before { sign_in user }
      it "returns unauthorized json" do
        get :edit
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST #toggle" do
    before { sign_in instructor }

    it "creates availability" do
      expect {
        post :toggle, params: { day: 'lundi', period: 'matin', available: true }, format: :json
      }.to change(InstructorAvailability, :count).by(1)
    end

    it "removes availability" do
      create(:instructor_availability, user: instructor, day: 'lundi', period: 'matin')
      expect {
        post :toggle, params: { day: 'lundi', period: 'matin', available: false }, format: :json
      }.to change(InstructorAvailability, :count).by(-1)
    end
  end
  
end
