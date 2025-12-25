FactoryBot.define do
  factory :tarif do
    annee { Date.today.year }
    tarif_horaire_avion1 { 150.0 }
    tarif_instructeur { 30.0 }
  end
end