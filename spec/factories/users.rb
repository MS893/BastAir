FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@bastair.com" }
    password { "password123" }
    nom { "Doe" }
    prenom { "John" }
    fonction { "pilote" }
    licence_type { "PPL" }
    num_licence { "12345678" }
    telephone { "0601020304" }
    num_ffa { "1234567" }
    type_medical { "Classe 2" }
    date_naissance { 30.years.ago }
    lieu_naissance { "Paris" }
    profession { "Pilote" }
    date_licence { Date.today + 1.year }
    medical { Date.today + 1.year }
    controle { Date.today + 1.year }
    cotisation_club { Date.today + 1.year }
    
    trait :admin do
      admin { true }
    end
    
    trait :instructeur do
      fonction { "instructeur" }
      fi { Date.today + 1.year }
    end
    
    trait :eleve do
      fonction { "eleve" }
    end
  end
end