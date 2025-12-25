# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transaction, type: :model do
  let(:user) { create(:user, solde: 0) }

  describe 'Associations' do
    it { should belong_to(:user).optional }
  end

  describe 'Validations' do
    it { should validate_presence_of(:date_transaction) }
    it { should validate_presence_of(:description) }
    it { should validate_length_of(:description).is_at_least(3) }
    it { should validate_presence_of(:mouvement) }
    it { should validate_inclusion_of(:mouvement).in_array(%w[Recette Dépense]) }
    it { should validate_presence_of(:montant) }
    it { should validate_numericality_of(:montant).is_greater_than(0) }
    it { should validate_presence_of(:source_transaction) }
    it { should validate_presence_of(:payment_method) }
  end

  describe 'Callbacks' do
    context 'when creating a transaction' do
      it 'updates user balance for Recette' do
        create(:transaction, user: user, mouvement: 'Recette', montant: 100)
        expect(user.reload.solde).to eq(100)
      end

      it 'updates user balance for Dépense' do
        create(:transaction, user: user, mouvement: 'Dépense', montant: 50)
        expect(user.reload.solde).to eq(-50)
      end
    end

    context 'when destroying a transaction' do
      it 'reverses user balance update' do
        t = create(:transaction, user: user, mouvement: 'Recette', montant: 100)
        t.destroy
        expect(user.reload.solde).to eq(0)
      end
    end
  end

  describe 'Scopes' do
    it 'hides discarded transactions by default' do
      t1 = create(:transaction)
      t2 = create(:transaction, deleted_at: Time.now)
      expect(Transaction.all).to include(t1)
      expect(Transaction.all).not_to include(t2)
    end
  end
end
