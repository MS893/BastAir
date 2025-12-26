# frozen_string_literal: true

FactoryBot.define do
  factory :reservation do
    association :user
    association :avion
    start_time { 1.day.from_now.change(hour: 10, min: 0) }
    end_time { 1.day.from_now.change(hour: 11, min: 0) }
    type_vol { 'Standard' }
  end
end
