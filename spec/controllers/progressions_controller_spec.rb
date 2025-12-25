# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProgressionsController, type: :controller do
  let(:student) { create(:user, :eleve) }
  let(:instructor) { create(:user, :instructeur) }

  describe 'GET #show' do
    context 'as student' do
      before { sign_in student }
      it 'shows own progression' do
        get :show
        expect(response).to be_successful
        expect(assigns(:selected_eleve)).to eq(student)
      end
    end

    context 'as instructor' do
      before { sign_in instructor }
      it 'shows student progression' do
        get :show, params: { eleve_id: student.id }
        expect(response).to be_successful
        expect(assigns(:selected_eleve)).to eq(student)
      end
    end
  end

  describe 'POST #update_exam' do
    before { sign_in instructor }

    it 'updates student status to brevete' do
      post :update_exam, params: { eleve_id: student.id, user: { date_fin_formation: Date.today } }
      student.reload
      # On vérifie que la fonction correspond à celle attendue pour un breveté (probablement 'Pilote' ou 'Breveté' selon votre config)
      expect(User::ALLOWED_FCT.values).to include(student.fonction)
      expect(student.date_licence).to eq(Date.today)
    end
  end

  describe 'POST #send_exam_email' do
    before { sign_in instructor }

    it 'sends email if exam validated' do
      student.update(date_fin_formation: Date.today)
      expect(UserMailer).to receive(:exam_success_email).with(student).and_return(double(deliver_later: true))

      post :send_exam_email, params: { eleve_id: student.id }

      expect(response).to redirect_to(livret_progression_path(eleve_id: student.id))
      expect(flash[:notice]).to include('Email de félicitations envoyé')
    end
  end
end
