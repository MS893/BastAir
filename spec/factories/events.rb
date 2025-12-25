FactoryBot.define do
  factory :event do
    title { "Pot" }
    description { "Description de l'événement" }
    start_date { Time.now + 1.day }
    duration { "3h" }
    price { 10 }
    association :admin, factory: [:user, :admin]
  end
end