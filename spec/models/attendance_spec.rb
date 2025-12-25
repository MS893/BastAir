require 'rails_helper'

RSpec.describe Attendance, type: :model do
  describe "Associations" do
    it { should belong_to(:user) }
    it { should belong_to(:event) }
  end

  describe "Validations" do
    # Nécessite un enregistrement existant pour tester l'unicité
    subject { create(:attendance) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:event_id).with_message("Vous êtes déjà inscrit à cet événement.") }
  end
end