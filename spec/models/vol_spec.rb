# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Vol, type: :model do
  describe 'Validations' do
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:avion) }
    it { should validate_presence_of(:depart) }
    it { should validate_presence_of(:arrivee) }
    it { should validate_presence_of(:debut_vol) }
    it { should validate_presence_of(:fin_vol) }
    it { should validate_presence_of(:duree_vol) }
    it { should validate_numericality_of(:duree_vol).is_greater_than(0) }
    it { should validate_presence_of(:compteur_depart) }
    it { should validate_presence_of(:compteur_arrivee) }

    it 'validates compteur_arrivee > compteur_depart' do
      vol = build(:vol, compteur_depart: 100, compteur_arrivee: 90)
      expect(vol).not_to be_valid
      expect(vol.errors[:compteur_arrivee]).to include('doit être supérieur au compteur de départ.')
    end
  end

  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:avion) }
    it { should belong_to(:instructeur).class_name('User').optional }
  end

  describe '#cout_total' do
    let!(:tarif) { create(:tarif, tarif_horaire_avion1: 100, tarif_instructeur: 50) }

    it 'calculates cost correctly for solo flight' do
      vol = build(:vol, duree_vol: 1.5, solo: true, instructeur: nil)
      expect(vol.cout_total).to eq(150.0) # 1.5 * 100
    end
  end
end
