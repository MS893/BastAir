# frozen_string_literal: true

FactoryBot.define do
  factory :course do
    sequence(:title) { |n| "FTP#{n} - Météorologie" }
    description { 'Cours théorique sur la météo.' }
  end
end
