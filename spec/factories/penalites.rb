# frozen_string_literal: true

FactoryBot.define do
  factory :penalite do
    association :user
    avion_immatriculation { 'F-GAAA' }
    reservation_start_time { Time.current }
    reservation_end_time { 1.hour.from_now }
    penalty_amount { 20 }
    status { 'En attente' }
    cancellation_reason { 'Raison personnelle' }
  end
end
