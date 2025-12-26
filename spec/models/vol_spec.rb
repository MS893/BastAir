# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Vol, type: :model do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:avion) }
    it { should belong_to(:instructeur).class_name('User').optional }
  end

  describe 'Validations' do
    it { should validate_presence_of(:depart) }
    it { should validate_presence_of(:arrivee) }
    it { should validate_presence_of(:debut_vol) }
    it { should validate_presence_of(:fin_vol) }
    it { should validate_presence_of(:compteur_depart) }
    it { should validate_presence_of(:compteur_arrivee) }
    it { should validate_presence_of(:duree_vol) }
    it { should validate_presence_of(:nb_atterro) }
    it { should validate_presence_of(:nature) }
    it { should validate_presence_of(:type_vol) }
  end
end
