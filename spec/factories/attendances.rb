FactoryBot.define do
  factory :attendance do
    association :user
    association :event
  end
end