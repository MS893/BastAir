FactoryBot.define do
  factory :penalite do
    association :user
    avion_immatriculation { "F-GAAA" }
    reservation_start_time { Time.now }
    reservation_end_time { Time.now + 1.hour }
    penalty_amount { 20 }
    status { "En attente" }
    cancellation_reason { "Raison personnelle" }
  end
end