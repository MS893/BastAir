require 'rails_helper'

RSpec.describe Avion, type: :model do
  describe "Validations" do
    subject { create(:avion) } # Nécessaire pour validate_uniqueness_of
    it { should validate_presence_of(:immatriculation) }
    it { should validate_uniqueness_of(:immatriculation) }
    it { should validate_presence_of(:marque) }
    it { should validate_presence_of(:modele) }
    it { should validate_presence_of(:moteur) }
    it { should validate_presence_of(:conso_horaire) }
    it { should validate_numericality_of(:conso_horaire).only_integer.is_greater_than(10) }
  end

  describe "Associations" do
    it { should have_many(:reservations).dependent(:destroy) }
    it { should have_many(:vols).dependent(:destroy) }
    it { should have_many(:signalements).dependent(:destroy) }
  end

  describe "#grounded?" do
    let(:avion) { create(:avion, potentiel_moteur: 100, next_50h: 50, next_100h: 100) }

    it "returns false when everything is ok" do
      expect(avion.grounded?).to be false
    end

    it "returns true when potential is exhausted" do
      avion.update(potentiel_moteur: 0)
      expect(avion.grounded?).to be true
    end

    it "returns true when annual visit is expired" do
      avion.update(annuelle: Date.yesterday)
      expect(avion.grounded?).to be true
    end
  end
end