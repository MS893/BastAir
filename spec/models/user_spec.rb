require 'rails_helper'

RSpec.describe User, type: :model do
  describe "Validations" do
    it { should validate_presence_of(:nom) }
    it { should validate_presence_of(:prenom) }
    
    context "when user is not BIA" do
      # On mocke is_bia? pour forcer le contexte non-BIA
      before { allow(subject).to receive(:is_bia?).and_return(false) }
      
      it { should validate_presence_of(:fonction) }
      it { should validate_inclusion_of(:fonction).in_array(User::ALLOWED_FCT.values) }
      it { should validate_presence_of(:licence_type) }
      it { should validate_inclusion_of(:licence_type).in_array(User::ALLOWED_LIC.values) }
    end
  end

  describe "Associations" do
    it { should have_many(:vols).dependent(:destroy) }
    it { should have_many(:transactions).dependent(:destroy) }
    it { should have_many(:reservations).dependent(:destroy) }
    it { should have_many(:attendances).dependent(:destroy) }
    it { should have_many(:events).through(:attendances) }
    it { should have_many(:signalements).dependent(:destroy) }
    it { should have_many(:instructor_availabilities).dependent(:destroy) }
    it { should have_many(:livrets).dependent(:destroy) }
  end

  describe "#full_name" do
    it "returns the concatenated first and last name" do
      user = build(:user, prenom: "Jean", nom: "Dupont")
      expect(user.full_name).to eq("Jean Dupont")
    end
  end

  describe "#credit_account" do
    let(:user) { create(:user, solde: 0) }

    it "creates a transaction and updates balance" do
      expect { user.credit_account(100) }.to change(Transaction, :count).by(1)
      expect(user.reload.solde).to eq(100)
    end
  end
end