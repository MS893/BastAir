# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Signalement, type: :model do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:avion) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:description) }
    it { should validate_inclusion_of(:status).in_array(['Ouvert', 'En cours', 'Résolu']) }
  end
end
