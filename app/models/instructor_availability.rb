class InstructorAvailability < ApplicationRecord
  belongs_to :user

  # Valide que le jour et la période sont parmi les valeurs autorisées
  validates :day, presence: true, inclusion: { in: %w[lundi mardi mercredi jeudi vendredi samedi dimanche] }
  validates :period, presence: true, inclusion: { in: %w[matin apres-midi] }
  # Assure qu'un instructeur ne peut avoir qu'une seule entrée pour un créneau donné
  validates :user_id, uniqueness: { scope: [:day, :period], message: "a déjà une disponibilité définie pour ce créneau." }
end
