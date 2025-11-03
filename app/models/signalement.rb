class Signalement < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :avion

  # Enums pour le statut
  STATUS_OPTIONS = ['Ouvert', 'En cours', 'Résolu']

  # Validations
  validates :description, presence: true, length: { minimum: 10 }
  validates :status, presence: true, inclusion: { in: STATUS_OPTIONS }
end
