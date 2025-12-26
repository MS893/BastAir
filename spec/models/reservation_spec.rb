# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reservation, type: :model do
  describe 'Validations' do
    it { should validate_presence_of(:start_time) }
    it { should validate_presence_of(:end_time) }

    it 'validates end_time is after start_time' do
      reservation = build(:reservation, start_time: Time.current, end_time: 1.hour.ago)
      expect(reservation).not_to be_valid
      expect(reservation.errors[:end_time]).to include("doit être après l'heure de début")
    end

    it 'validates within allowed hours' do
      # 6h du matin (trop tôt)
      reservation = build(:reservation, start_time: Time.current.change(hour: 6))
      expect(reservation).not_to be_valid
      expect(reservation.errors[:start_time]).to include('doit être entre 7h00 et 17h00')
    end
  end

  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:avion) }
  end
end
