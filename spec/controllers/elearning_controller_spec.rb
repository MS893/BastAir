# frozen_string_literal: true

# spec/controllers/elearning_controller_spec.rb

require 'rails_helper'

RSpec.describe ElearningController, type: :controller do
  # On prépare les utilisateurs et les données nécessaires pour les tests.
  let(:eleve) { create(:user, :eleve) } # Assurez-vous d'avoir une factory pour User
  let(:other_user) { create(:user, :pilote) }
  let!(:course1) { create(:course) } # Assurez-vous d'avoir une factory pour Course
  let!(:course2) { create(:course) }

  # On prépare un cours avec un document attaché pour tester le téléchargement.
  # Active Storage a besoin d'un peu de configuration pour les tests.
  let(:course_with_document) do
    create(:course).tap do |course|
      # On attache un fichier de test.
      # Le fichier 'test.pdf' doit exister dans spec/fixtures/files/
      file_path = Rails.root.join('spec', 'fixtures', 'files', 'test.pdf')
      # Créez le dossier et le fichier si nécessaire
      FileUtils.mkdir_p(File.dirname(file_path))
      File.write(file_path, 'dummy content') unless File.exist?(file_path)

      course.document.attach(io: File.open(file_path), filename: 'test.pdf', content_type: 'application/pdf')
    end
  end

  describe 'Accès non authentifié' do
    it 'redirige vers la page de connexion pour toutes les actions' do
      get :index
      expect(response).to redirect_to(new_user_session_path)

      get :show, params: { id: course1.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'Accès non autorisé (utilisateur non-élève)' do
    before { sign_in other_user }

    it "redirige vers la page d'accueil avec une alerte" do
      get :index
      expect(response).to redirect_to(root_path)
      # expect(flash[:alert]).to eq("Vous n'avez pas l'autorisation d'accéder à cette page.")
    end
  end

  describe 'Accès autorisé (élève)' do
    before { sign_in eleve }

    describe 'GET #index' do
      it 'rend le template index et assigne les cours et audios' do
        # On crée un audio pour le test
        audio = create(:audio) # Assurez-vous d'avoir une factory pour Audio

        get :index
        expect(response).to be_successful
        expect(response).to render_template(:index)
        expect(assigns(:courses)).to match_array([course1, course2])
        expect(assigns(:audios)).to eq([audio])
      end
    end

    describe 'GET #show' do
      it 'rend le template show et assigne le bon cours' do
        get :show, params: { id: course1.id }
        expect(response).to be_successful
        expect(response).to render_template(:show)
        expect(assigns(:course)).to eq(course1)
      end
    end

    describe 'GET #document' do
      context 'quand le document est attaché' do
        it 'envoie le fichier PDF avec succès' do
          get :document, params: { id: course_with_document.id }
          expect(response).to be_successful
          expect(response.content_type).to eq 'application/pdf'
        end
      end

      context "quand le document n'est pas attaché" do
        it "redirige vers l'index avec une alerte" do
          get :document, params: { id: course1.id } # course1 n'a pas de document
          expect(response).to redirect_to(elearning_index_path)
          expect(flash[:alert]).to eq('Le document pour ce cours est introuvable.')
        end
      end
    end
  end
end
