# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Livret, type: :model do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:course).optional }
    it { should belong_to(:flight_lesson).optional }
  end

  describe 'Validations' do
    it 'validates that course and flight_lesson are not both present' do
      livret = build(:livret, course: create(:course), flight_lesson: create(:flight_lesson))
      expect(livret).not_to be_valid
      expect(livret.errors[:base]).to include('Un livret ne peut pas être associé à la fois à un cours théorique et à une leçon de vol.')
    end
  end

  describe 'Callbacks' do
    let(:livret) { create(:livret, status: 0) }

    it 'sets date to today when status becomes validated (3)' do
      livret.update(status: 3)
      expect(livret.date).to eq(Time.zone.today)
    end

    it 'clears date if status changes from validated to something else' do
      livret.update(status: 3)
      livret.update(status: 1)
      expect(livret.date).to be_nil
    end
  end

  describe '#display_title' do
    it 'returns course title if associated' do
      course = create(:course, title: 'Météo')
      livret = create(:livret, course: course, flight_lesson: nil)
      expect(livret.display_title).to eq('Météo')
    end

    it 'returns own title if no association' do
      livret = create(:livret, title: 'Exam', course: nil, flight_lesson: nil)
      expect(livret.display_title).to eq('Exam')
    end
  end
end
