# frozen_string_literal: true

FactoryBot.define do
  factory :question do
    association :course
    content { 'Quelle est la réponse ?' }
    answer_1 { 'Réponse A' }
    answer_2 { 'Réponse B' }
    answer_3 { 'Réponse C' }
    correct_answer { 1 }
  end
end
