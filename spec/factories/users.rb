# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@bastair.com" }
    password { 'password123' }
    nom { 'Doe' }
    prenom { 'John' }
    # Tente de trouver un rôle "Pilote" par défaut, sinon prend une valeur au hasard
    fonction { User::ALLOWED_FCT.values.find { |v| v.to_s.match?(/pilote/i) } || User::ALLOWED_FCT.values.first }
    licence_type { 'PPL' }
    num_licence { '12345678' }
    telephone { '0601020304' }
    num_ffa { '1234567' }
    type_medical { 'Classe 2' }
    date_naissance { 30.years.ago }
    lieu_naissance { 'Paris' }
    profession { 'Pilote' }
    date_licence { Time.zone.today + 1.year }
    medical { Time.zone.today + 1.year }
    controle { Time.zone.today + 1.year }
    cotisation_club { Time.zone.today + 1.year }

    trait :admin do
      admin { true }
    end

    trait :instructeur do
      fonction { User::ALLOWED_FCT.values.find { |v| v.to_s.match?(/instructeur/i) } || User::ALLOWED_FCT.values.last }
      fi { Time.zone.today + 1.year }
    end

    trait :eleve do
      fonction { User::ALLOWED_FCT.values.find { |v| v.to_s.match?(/eleve|élève/i) } || User::ALLOWED_FCT.values.first }
    end

    trait :pilote do
      fonction { User::ALLOWED_FCT.values.find { |v| v.to_s.match?(/pilote/i) } || User::ALLOWED_FCT.values.first }
    end

    trait :tresorier do
      fonction { User::ALLOWED_FCT.values.find { |v| v.to_s.match?(/tresorier|trésorier/i) } || User::ALLOWED_FCT.values.first }
    end
  end
end
