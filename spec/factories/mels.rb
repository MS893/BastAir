# frozen_string_literal: true

FactoryBot.define do
  factory :mel do
    association :avion
    description { 'Élément hors service' }
    date_signalement { Time.zone.today }
    status { 'Ouvert' }
  end
end
