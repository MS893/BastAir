# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LivretsController, type: :controller do
  let(:student) { create(:user, :eleve) }
  let(:instructor) { create(:user, :instructeur) }
  let(:other_student) { create(:user, :eleve) }

  # On suppose que les factories course et flight_lesson existent
  let(:course) { create(:course) }
  let(:flight_lesson) { create(:flight_lesson) }

  # Création des livrets associés
  let!(:livret_course) { create(:livret, user: student, course: course, flight_lesson: nil) }
  let!(:livret_lesson) { create(:livret, user: student, flight_lesson: flight_lesson, course: nil) }

  describe 'GET #show' do
    context 'when user is signed in' do
      before { sign_in student }

      it 'redirects to signature path' do
        get :show, params: { id: livret_course.id }
        expect(response).to redirect_to(signature_livret_path(livret_course))
      end
    end

    context 'when user is not signed in' do
      it 'redirects to sign in' do
        get :show, params: { id: livret_course.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET #signature' do
    before { sign_in student }

    context 'as the owner' do
      it 'returns success' do
        get :signature, params: { id: livret_course.id }
        expect(response).to be_successful
      end
    end

    context 'as an instructor' do
      before { sign_in instructor }
      it 'returns success' do
        get :signature, params: { id: livret_course.id }
        expect(response).to be_successful
      end
    end

    context 'as another unauthorized student' do
      before { sign_in other_student }
      it 'redirects with alert' do
        get :signature, params: { id: livret_course.id }
        expect(response).to redirect_to(elearning_index_path)
        expect(flash[:alert]).to eq("Vous n'êtes pas autorisé à voir cette signature.")
      end
    end
  end

  describe 'PATCH #update' do
    # Données factices pour simuler une image en base64
    let(:signature_data) do
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
    end

    context 'Student signing a theory course (FTP)' do
      before { sign_in student }

      it 'updates signature and status, then redirects to elearning index' do
        patch :update, params: {
          id: livret_course.id,
          livret: { signature_data: signature_data }
        }

        livret_course.reload
        expect(livret_course.status).to eq(3) # Statut validé
        expect(response).to redirect_to(elearning_index_path)
        expect(flash[:notice]).to eq('Cours validé et signé avec succès !')
      end
    end

    context 'Student signing a flight lesson' do
      before { sign_in student }

      context 'when instructor has NOT signed yet' do
        it 'prevents signature and redirects' do
          patch :update, params: {
            id: livret_lesson.id,
            livret: { signature_data: signature_data }
          }

          expect(response).to redirect_to(signature_livret_path(livret_lesson))
          expect(flash[:alert]).to include("Vous ne pouvez pas signer cette leçon tant que l'instructeur ne l'a pas signée")
        end
      end
    end

    context 'Instructor signing a flight lesson' do
      before { sign_in instructor }

      it 'updates instructor_signature_data and redirects to progression' do
        # Le contrôleur détecte que c'est un instructeur et assigne la signature au bon champ
        patch :update, params: {
          id: livret_lesson.id,
          livret: { signature_data: signature_data }
        }

        expect(response).to redirect_to(livret_progression_path(eleve_id: student.id))
        expect(flash[:notice]).to eq('Livret mis à jour avec succès.')
      end
    end
  end
end
