# frozen_string_literal: true

FactoryBot.define do
  factory :setting do
    sequence(:var) { |n| "setting_#{n}" }
    val { 'valeur' }
  end
end
