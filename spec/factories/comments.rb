# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    association :user
    association :event
    content { 'Ceci est un commentaire pertinent.' }
  end
end
