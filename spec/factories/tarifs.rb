# frozen_string_literal: true

FactoryBot.define do
  factory :tarif do
    annee { Time.zone.today.year }
    tarif_horaire_avion1 { 150.0 }
    tarif_instructeur { 30.0 }
  end
end
