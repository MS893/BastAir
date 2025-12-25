# frozen_string_literal: true

FactoryBot.define do
  factory :instructor_availability do
    association :user, factory: %i[user instructeur]
    day { 'lundi' }
    period { 'matin' }
  end
end
