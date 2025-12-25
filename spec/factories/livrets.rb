# frozen_string_literal: true

FactoryBot.define do
  factory :livret do
    association :user
    title { 'Livret Test' }
    status { 0 }
  end
end
