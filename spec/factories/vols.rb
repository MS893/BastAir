# frozen_string_literal: true

FactoryBot.define do
  factory :vol do
    association :user, factory: %i[user pilote]
    association :avion
    depart { 'LFPT' }
    arrivee { 'LFPT' }
    debut_vol { Time.current }
    duree_vol { 1.0 }
    compteur_depart { 1000.0 }
    compteur_arrivee { 1001.0 }
    nb_atterro { 1 }
    nature { 'VFR de jour' }
    type_vol { 'Standard' }
    solo { true }

    # Si l'utilisateur est un élève, on ajoute un instructeur pour passer la validation
    after(:build) do |vol|
      vol.instructeur ||= create(:user, :instructeur) if vol.user&.eleve?
    end
  end
end
