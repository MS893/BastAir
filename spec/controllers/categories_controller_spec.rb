require 'rails_helper'

RSpec.describe CategoriesController, type: :controller do
  describe "GET #index" do
    it "returns categories json" do
      get :index
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json).to have_key('recette')
      expect(json).to have_key('depense')
    end
  end
  
end
