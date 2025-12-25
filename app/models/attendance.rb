# frozen_string_literal: true

class Attendance < ApplicationRecord
  belongs_to :user
  belongs_to :event

  # Empêche un utilisateur de s'inscrire plusieurs fois au même événement
  validates :user_id, uniqueness: { scope: :event_id, message: 'Vous êtes déjà inscrit à cet événement.' }
end
