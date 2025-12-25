FactoryBot.define do
  factory :audio do
    sequence(:title) { |n| "Podcast #{n}" }
    description { "Description du podcast" }
  end
end