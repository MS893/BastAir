FactoryBot.define do
  factory :signalement do
    association :user
    association :avion
    description { "Problème signalé sur la radio de bord." }
    status { "Ouvert" }
  end
end