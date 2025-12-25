# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Event, type: :model do
  describe 'Validations' do
    it { should validate_presence_of(:title) }
    it { should validate_inclusion_of(:title).in_array(Event::ALLOWED_TITLES) }
    it { should validate_presence_of(:description) }
    it { should validate_length_of(:description).is_at_least(5) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:duration) }
    it { should validate_presence_of(:price) }
    it { should validate_numericality_of(:price).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe 'Associations' do
    it { should belong_to(:admin).class_name('User') }
    it { should have_many(:attendances).dependent(:destroy) }
    it { should have_many(:users).through(:attendances) }
    it { should have_many(:comments).dependent(:destroy) }
  end

  describe '#is_free?' do
    it 'returns true if price is 0' do
      event = build(:event, price: 0)
      expect(event.is_free?).to be true
    end
  end
end
