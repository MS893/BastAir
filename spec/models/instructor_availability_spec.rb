require 'rails_helper'

RSpec.describe InstructorAvailability, type: :model do
  describe "Associations" do
    it { should belong_to(:user) }
  end

  describe "Validations" do
    it { should validate_presence_of(:day) }
    it { should validate_inclusion_of(:day).in_array(%w[lundi mardi mercredi jeudi vendredi samedi dimanche]) }
    it { should validate_presence_of(:period) }
    it { should validate_inclusion_of(:period).in_array(%w[matin apres-midi]) }
    # Note: Uniqueness validation requires an existing record in the database to test against
  end
end
