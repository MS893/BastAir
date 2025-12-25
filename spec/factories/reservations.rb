# frozen_string_literal: true

FactoryBot.define do
  factory :reservation do
    association :user
    association :avion
    start_time { (Time.zone.now + 1.day).change(hour: 10, min: 0) }
    end_time { (Time.zone.now + 1.day).change(hour: 11, min: 0) }
    type_vol { 'Standard' }
  end
end
