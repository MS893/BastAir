# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AvatarsController, type: :controller do
  let(:user) { create(:user) }
  let(:file) { fixture_file_upload(Rails.root.join('spec/fixtures/files/test.jpg'), 'image/jpeg') }

  before do
    # Créer le fichier dummy si nécessaire
    FileUtils.mkdir_p(Rails.root.join('spec/fixtures/files'))
    Rails.root.join('spec/fixtures/files/test.jpg').write('dummy image') unless Rails.root.join('spec/fixtures/files/test.jpg').exist?
  end

  describe 'POST #create' do
    it 'attaches avatar to user' do
      post :create, params: { user_id: user.id, avatar: file }
      expect(user.reload.avatar).to be_attached
      expect(response).to redirect_to(user_path(user))
    end
  end
end
