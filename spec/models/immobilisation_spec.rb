require 'rails_helper'

RSpec.describe Immobilisation, type: :model do
  describe "Associations" do
    it { should belong_to(:purchase_transaction).class_name('Transaction').optional }
  end

  describe "Validations" do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:date_acquisition) }
    it { should validate_presence_of(:valeur_acquisition) }
    it { should validate_numericality_of(:valeur_acquisition).is_greater_than(0) }
    it { should validate_presence_of(:duree_amortissement) }
    it { should validate_numericality_of(:duree_amortissement).only_integer.is_greater_than(0) }
    
    it "validates date_acquisition cannot be in the future" do
      immob = build(:immobilisation, date_acquisition: Date.tomorrow)
      expect(immob).not_to be_valid
      expect(immob.errors[:date_acquisition]).to include("ne peut pas être dans le futur")
    end
  end

  describe "Methods" do
    let(:immob) { create(:immobilisation, valeur_acquisition: 1000, duree_amortissement: 5, date_acquisition: Date.new(2020, 1, 1)) }

    it "calculates amortissement_annuel" do
      expect(immob.amortissement_annuel).to eq(200)
    end

    it "calculates amortissements_cumules" do
      # 2022 - 2020 = 2 ans d'amortissement complets
      expect(immob.amortissements_cumules(2022)).to eq(400)
    end
  end
end