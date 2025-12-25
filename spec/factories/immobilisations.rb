# frozen_string_literal: true

FactoryBot.define do
  factory :immobilisation do
    description { 'Achat Avion Test' }
    date_acquisition { Date.today - 1.year }
    valeur_acquisition { 50_000 }
    duree_amortissement { 10 }
  end
end
