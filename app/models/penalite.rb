# frozen_string_literal: true

class Penalite < ApplicationRecord
  # --- Associations ---
  belongs_to :user
  belongs_to :admin, class_name: 'User', optional: true

  # --- Validations ---
  validates :avion_immatriculation, presence: true
  validates :reservation_start_time, presence: true
  validates :reservation_end_time, presence: true
  validates :penalty_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: ['En attente', 'Appliquée', 'Annulée'] }
  validates :cancellation_reason, presence: true
end
