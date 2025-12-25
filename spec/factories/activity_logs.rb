# frozen_string_literal: true

FactoryBot.define do
  factory :activity_log do
    association :user
    action { 'update' }
    description { "Mise à jour d'une entité" }
    entity_type { 'Avion' }
    sequence(:entity_id) { |n| n }
  end
end
