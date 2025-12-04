class Reservation < ApplicationRecord
  # == Associations ===========================================================
  belongs_to :user
  belongs_to :avion

  # == Validations ============================================================
  validates :start_time, :end_time, presence: true
  
  # --- DÉBUT DE L'AJOUT ---
  validate :end_time_after_start_time
  validate :no_overlapping_reservations
  validate :within_allowed_hours

  private

  # S'assure que l'heure de fin est bien après l'heure de début.
  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "doit être après l'heure de début")
    end
  end

  # S'assure qu'il n'y a pas de réservation qui se chevauche pour le même avion.
  def no_overlapping_reservations
    return if start_time.blank? || end_time.blank? || avion_id.blank?

    # Recherche les réservations qui se chevauchent pour le même avion.
    # Un chevauchement existe si une autre réservation commence avant la fin de celle-ci
    # ET se termine après le début de celle-ci.
    overlapping =  Reservation.where(avion_id: avion_id)
                              .where.not(id: id) # Exclut l'enregistrement actuel lors d'une mise à jour
                              .where("start_time < ? AND end_time > ?", end_time, start_time)

    if overlapping.exists?
      errors.add(:base, "Un autre vol est déjà réservé sur cet avion pendant ce créneau.")
    end
  end

  # S'assure que la réservation se fait dans les heures autorisées (7h à 17h)
  def within_allowed_hours
    return if start_time.blank?

    # On vérifie si l'heure de début est en dehors de la plage 7h - 17h (inclu)
    if start_time.hour < 7 || start_time.hour > 17
      errors.add(:start_time, "doit être entre 7h00 et 17h00")
    end
  end

end