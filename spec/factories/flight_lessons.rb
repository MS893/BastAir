FactoryBot.define do
  factory :flight_lesson do
    sequence(:title) { |n| "Leçon de vol #{n}" }
    description { "Apprentissage des bases du pilotage." }
  end
end