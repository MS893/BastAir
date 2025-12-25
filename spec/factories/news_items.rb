# frozen_string_literal: true

FactoryBot.define do
  factory :news_item do
    association :user, factory: %i[user admin]
    title { 'Information importante' }
    content { "Ceci est le contenu de l'actualité." }
  end
end
