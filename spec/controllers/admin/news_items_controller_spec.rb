# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::NewsItemsController, type: :controller do
  let(:admin) { create(:user, admin: true) }
  # On crée une factory minimale pour NewsItem si elle n'existe pas
  let(:news_item) { NewsItem.create!(title: 'Info', content: 'Contenu', user: admin) }

  before { sign_in admin }

  describe 'GET #index' do
    it 'répond avec succès' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'GET #new' do
    it 'répond avec succès' do
      get :new
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) { { title: 'Nouvelle consigne', content: 'Important !' } }

    it 'crée une nouvelle consigne' do
      expect do
        post :create, params: { news_item: valid_attributes }
      end.to change(NewsItem, :count).by(1)
      expect(response).to redirect_to(admin_news_items_path)
    end
  end

  describe 'GET #edit' do
    it 'répond avec succès' do
      get :edit, params: { id: news_item.id }
      expect(response).to be_successful
    end
  end

  describe 'PATCH #update' do
    it 'met à jour la consigne' do
      patch :update, params: { id: news_item.id, news_item: { title: 'Titre modifié' } }
      expect(news_item.reload.title).to eq('Titre modifié')
      expect(response).to redirect_to(admin_news_items_path)
    end
  end

  describe 'DELETE #destroy' do
    it 'supprime la consigne' do
      item_to_delete = NewsItem.create!(title: 'To delete', content: '...', user: admin)
      expect do
        delete :destroy, params: { id: item_to_delete.id }
      end.to change(NewsItem, :count).by(-1)
    end
  end
end
