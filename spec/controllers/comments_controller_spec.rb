# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommentsController, type: :controller do
  let(:user) { create(:user) }
  let(:event) { create(:event) }
  let!(:comment) { create(:comment, user: user, event: event) }

  before { sign_in user }

  describe 'POST #create' do
    it 'creates a comment' do
      # Un user ne peut commenter qu'une fois par event selon le contrôleur
      other_event = create(:event)
      expect do
        post :create, params: { event_id: other_event.id, comment: { content: 'Super !' } }
      end.to change(Comment, :count).by(1)
    end
  end

  describe 'PATCH #update' do
    it 'updates own comment' do
      patch :update, params: { event_id: event.id, id: comment.id, comment: { content: 'Updated' } }
      expect(comment.reload.content).to eq('Updated')
    end

    it 'prevents updating others comment' do
      other_comment = create(:comment, event: event) # Created by another user factory default
      patch :update, params: { event_id: event.id, id: other_comment.id, comment: { content: 'Hacked' } }
      expect(response).to redirect_to(event_path(event))
      expect(flash[:danger]).to eq('Action impossible')
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes own comment' do
      expect do
        delete :destroy, params: { event_id: event.id, id: comment.id }
      end.to change(Comment, :count).by(-1)
    end
  end
end
