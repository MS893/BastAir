# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    title { 'Pot' }
    description { "Description de l'événement" }
    start_date { 1.day.from_now }
    duration { '3h' }
    price { 10 }
    association :admin, factory: %i[user admin]
  end
end
