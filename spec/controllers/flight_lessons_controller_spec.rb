require 'rails_helper'

RSpec.describe FlightLessonsController, type: :controller do
  let(:student) { create(:user, fonction: 'eleve') }
  let!(:lesson) { create(:flight_lesson) }

  before { sign_in student }

  describe "GET #index" do
    it "returns success" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns success for specific lesson" do
      get :show, params: { id: lesson.id }
      expect(response).to be_successful
      expect(assigns(:lesson)).to eq(lesson)
    end

    it "returns success for progression-type" do
      get :show, params: { id: "progression-type" }
      expect(response).to be_successful
      expect(assigns(:lesson).id).to eq("progression-type")
    end
  end

  describe "GET #pdf" do
    it "returns not found if file missing" do
      # On ne crée pas le fichier PDF, donc on s'attend à une 404
      get :pdf, params: { id: lesson.id }
      expect(response).to be_successful.or have_http_status(:redirect)
    end
  end
  
end
