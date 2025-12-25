# frozen_string_literal: true

FactoryBot.define do
  factory :attendance do
    association :user
    association :event
  end
end
