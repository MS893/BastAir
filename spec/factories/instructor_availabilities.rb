FactoryBot.define do
  factory :instructor_availability do
    association :user, factory: [:user, :instructeur]
    day { "lundi" }
    period { "matin" }
  end
end