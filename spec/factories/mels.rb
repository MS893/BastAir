FactoryBot.define do
  factory :mel do
    association :avion
    description { "Élément hors service" }
    date_signalement { Date.today }
    status { "Ouvert" }
  end
end