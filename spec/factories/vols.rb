FactoryBot.define do
  factory :vol do
    association :user
    association :avion
    depart { "LFPT" }
    arrivee { "LFPT" }
    debut_vol { Time.now }
    duree_vol { 1.0 }
    compteur_depart { 1000.0 }
    compteur_arrivee { 1001.0 }
    nb_atterro { 1 }
    nature { "VFR de jour" }
    type_vol { "Standard" }
    solo { true }
  end
end