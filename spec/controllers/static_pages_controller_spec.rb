# frozen_string_literal: true

# spec/controllers/static_pages_controller_spec.rb

require 'rails_helper'

RSpec.describe StaticPagesController, type: :controller do
  describe 'GET #download' do
    let(:filename) { 'test_document.txt' }
    let(:file_path) { Rails.root.join('app', 'assets', 'files', 'download', filename) }

    before do
      # On crée un fichier de test pour s'assurer qu'il existe
      dir = File.dirname(file_path)
      FileUtils.mkdir_p(dir)
      File.write(file_path, 'Ceci est un test.')
    end

    after do
      # On nettoie le fichier après le test
      FileUtils.rm_f(file_path)
    end

    context 'when the file exists' do
      it 'sends the file as an attachment' do
        get :download, params: { filename: filename }

        expect(response).to be_successful
        # On vérifie que le header 'Content-Disposition' force le téléchargement
        expect(response.headers['Content-Disposition']).to include("attachment; filename=\"#{filename}\"")
        # On vérifie que le contenu du corps de la réponse est bien celui du fichier
        expect(response.body).to eq('Ceci est un test.')
      end
    end

    context 'when the file does not exist' do
      it 'redirects with an alert' do
        get :download, params: { filename: 'fichier_inexistant.pdf' }

        expect(response).to redirect_to(documents_divers_path)
        expect(flash[:alert]).to eq("Le fichier demandé n'existe pas.")
      end
    end
  end
end
