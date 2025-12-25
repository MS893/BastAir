FactoryBot.define do
  factory :comment do
    association :user
    association :event
    content { "Ceci est un commentaire pertinent." }
  end
end