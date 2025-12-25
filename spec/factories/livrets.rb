FactoryBot.define do
  factory :livret do
    association :user
    title { "Livret Test" }
    status { 0 }
  end
end