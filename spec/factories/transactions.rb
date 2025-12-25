# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    date_transaction { Date.today }
    description { 'Transaction test' }
    mouvement { 'Recette' }
    montant { 100.0 }
    source_transaction { 'Cotisations des Membres' }
    payment_method { 'Virement' }
    association :user
  end
end
