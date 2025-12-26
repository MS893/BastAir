# frozen_string_literal: true

FactoryBot.define do
  factory :avion do
    sequence(:immatriculation) { |n| "F-G#{n}AA" }
    marque { 'Robin' }
    modele { 'DR400' }
    moteur { 'Lycoming' }
    conso_horaire { 25 }
    tbo_helice { Time.zone.today + 1.year }
    tbo_parachute { Time.zone.today + 1.year }
    _1000h { Time.zone.today + 1.year }
    potentiel_moteur { 1000 }
    # Pas besoin d'attacher cen_document car la validation n'est pas 'presence: true'
  end
end
