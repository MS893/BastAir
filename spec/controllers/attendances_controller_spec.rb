# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AttendancesController, type: :controller do
  let(:user) { create(:user, solde: 100) }
  let(:free_event) { create(:event, price: 0) }
  let(:paid_event) { create(:event, price: 50) }

  before { sign_in user }

  describe 'POST #create' do
    context 'free event' do
      it 'creates attendance without transaction' do
        expect do
          post :create, params: { event_id: free_event.id }
        end.to change(Attendance, :count).by(1)
                                        .and change(Transaction, :count).by(0)
      end
    end

    context 'paid event' do
      it 'creates attendance and debits user' do
        expect do
          post :create, params: { event_id: paid_event.id }
        end.to change(Attendance, :count).by(1)
                                        .and change(Transaction, :count).by(1)

        user.reload
        expect(user.solde).to eq(50)
      end

      it 'fails if insufficient funds' do
        user.update(solde: 10)
        post :create, params: { event_id: paid_event.id }
        expect(response).to redirect_to(paid_event)
        expect(flash[:alert]).to include('solde est insuffisant')
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'paid event' do
      before do
        # Setup initial state manually to simulate existing attendance
        Transaction.create!(user: user, montant: 50, mouvement: 'Dépense', description: 'test',
                            source_transaction: 'Charges Exceptionnelles', payment_method: 'Prélèvement sur compte', date_transaction: Time.zone.today)
      end
      let!(:attendance) { Attendance.create!(user: user, event: paid_event) }

      it 'refunds user' do
        expect do
          delete :destroy, params: { event_id: paid_event.id, id: attendance.id }
        end.to change(Attendance, :count).by(-1)
                                        .and change(Transaction, :count).by(1) # Refund transaction

        expect(flash[:notice]).to include('recrédité')
      end
    end
  end
end
