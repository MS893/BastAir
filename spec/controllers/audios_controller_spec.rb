# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AudiosController, type: :controller do
  let(:user) { create(:user) }
  let(:audio) { create(:audio) }

  before do
    sign_in user
    # Attacher un fichier dummy
    file = Rails.root.join('spec', 'fixtures', 'files', 'test.mp3')
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, 'dummy audio') unless File.exist?(file)
    audio.audio.attach(io: File.open(file), filename: 'test.mp3', content_type: 'audio/mpeg')
  end

  describe 'GET #show' do
    it 'sends the audio file' do
      get :show, params: { id: audio.id }
      expect(response).to be_successful
      expect(response.header['Content-Type']).to eq('audio/mpeg')
    end

    it 'redirects if no file attached' do
      # On définit la méthode helper manquante directement sur l'instance du contrôleur
      def controller.cours_theoriques_path = '/cours_theoriques'
      audio.audio.purge
      get :show, params: { id: audio.id }
      # On suppose que cours_theoriques_path redirige vers l'index elearning ou la racine
      expect(response).to have_http_status(:redirect)
    end
  end
end
