# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Penalite, type: :model do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:admin).class_name('User').optional }
  end

  describe 'Validations' do
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:avion_immatriculation) }
    it { should validate_presence_of(:penalty_amount) }
    it { should validate_numericality_of(:penalty_amount).is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(['En attente', 'Appliquée', 'Annulée']) }
  end
end
