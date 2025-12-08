class Setting < ApplicationRecord
  # == Constants ==============================================================

  # Définit une source unique de vérité pour les fuseaux horaires autorisés dans l'application.
  # Le `.freeze` empêche la modification de ce tableau à l'exécution.
  ALLOWED_TIME_ZONES = [
    'Europe/Paris', 'UTC', 'America/Martinique', 'America/Cayenne',
    'Indian/Reunion', 'Pacific/Noumea', 'Pacific/Tahiti', 'Pacific/Marquesas'
  ].freeze

  # == Validations ============================================================
  validates :var, presence: true, uniqueness: true
end
