# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Penalite, type: :model do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:admin).class_name('User').optional }
  end

  describe 'Validations' do
    it { should validate_presence_of(:avion_immatriculation) }
    it { should validate_presence_of(:reservation_start_time) }
    it { should validate_presence_of(:reservation_end_time) }
    it { should validate_presence_of(:penalty_amount) }
    it { should validate_presence_of(:cancellation_reason) }
  end
end
