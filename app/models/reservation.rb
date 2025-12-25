# frozen_string_literal: true

class Reservation < ApplicationRecord
  # == Attributs virtuels pour le formulaire de saisie de date/heure ==
  attr_accessor :start_date, :start_hour, :start_minute, :end_date, :end_hour, :end_minute

  # == Associations ===========================================================
  belongs_to :user
  belongs_to :avion

  # == Callbacks ==============================================================
  after_initialize :set_virtual_datetime_attributes, if: :new_record?

  # == Validations ============================================================
  validates :start_time, :end_time, presence: true
  validate :end_time_after_start_time
  validate :no_overlapping_reservations
  validate :within_allowed_hours
  validate :instructor_required_if_instruction
  validate :instructor_is_available, if: -> { instruction? && fi.present? }
  validate :avion_disponible_pour_reservation

  private

  # Initialise les attributs virtuels de date/heure.
  # - Pour un nouvel enregistrement, il met des valeurs par défaut.
  # - Pour un enregistrement existant, il les peuple à partir de start_time/end_time.
  def set_virtual_datetime_attributes
    self.start_date ||= (start_time || Time.zone.now).to_date
    self.start_hour ||= 7
    self.start_minute ||= 0
    self.end_date ||= (end_time || Time.zone.now).to_date
    self.end_hour ||= 7
    self.end_minute ||= 15
  end

  # S'assure que l'heure de fin est bien après l'heure de début.
  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    return unless end_time <= start_time

    errors.add(:end_time, "doit être après l'heure de début")
  end

  # S'assure qu'il n'y a pas de réservation qui se chevauche pour le même avion.
  def no_overlapping_reservations
    return if start_time.blank? || end_time.blank? || avion_id.blank?

    # Recherche les réservations qui se chevauchent pour le même avion.
    # Un chevauchement existe si une autre réservation commence avant la fin de celle-ci
    # ET se termine après le début de celle-ci.
    overlapping = Reservation.where(avion_id: avion_id)
                             .where.not(id: id) # Exclut l'enregistrement actuel lors d'une mise à jour
                             .where('start_time < ? AND end_time > ?', end_time, start_time)

    return unless overlapping.exists?

    errors.add(:base, 'Un autre vol est déjà réservé sur cet avion pendant ce créneau.')
  end

  # S'assure que la réservation se fait dans les heures autorisées (7h à 17h)
  def within_allowed_hours
    return if start_time.blank?

    # On vérifie si l'heure de début est en dehors de la plage 7h - 17h (inclu)
    return unless start_time.hour < 7 || start_time.hour > 17

    errors.add(:start_time, 'doit être entre 7h00 et 17h00')
  end

  # S'assure qu'un instructeur est sélectionné si le vol est en instruction.
  def instructor_required_if_instruction
    return unless instruction? && fi.blank?

    errors.add(:fi, 'doit être sélectionné pour un vol en instruction')
  end

  # S'assure que l'instructeur est disponible sur le créneau de la réservation.
  def instructor_is_available
    return if start_time.blank?

    # Retrouver l'objet User de l'instructeur à partir de son nom complet
    first_name, last_name = fi.split(' ', 2)
    instructor = User.find_by(prenom: first_name, nom: last_name)

    unless instructor
      errors.add(:fi, "Instructeur '#{fi}' introuvable.")
      return
    end

    # Déterminer le jour et la période de la réservation
    reservation_day = start_time.strftime('%A').downcase # ex: "monday"
    # Les jours en base sont en français (ex: "lundi")
    day_translation = { 'monday' => 'lundi', 'tuesday' => 'mardi', 'wednesday' => 'mercredi', 'thursday' => 'jeudi',
                        'friday' => 'vendredi', 'saturday' => 'samedi', 'sunday' => 'dimanche' }
    reservation_day_fr = day_translation[reservation_day]

    # Définir les périodes possibles en fonction de l'heure de début
    # Matin: jusqu'à 13h
    # Après-midi: à partir de 12h
    possible_periods = []
    possible_periods << 'matin' if start_time.hour <= 13
    possible_periods << 'apres-midi' if start_time.hour >= 12

    # S'il n'y a aucune période possible (ex: vol à 5h du matin), on bloque.
    if possible_periods.empty?
      return errors.add(:base,
                        'La réservation est en dehors des créneaux de disponibilité (matin/après-midi).')
    end

    # Vérifier si au moins une disponibilité correspondante existe pour l'une des périodes possibles.
    is_available = instructor.instructor_availabilities.where(day: reservation_day_fr, period: possible_periods).exists?

    errors.add(:base, "L'instructeur n'est pas disponible sur ce créneau.") unless is_available
  end

  def avion_disponible_pour_reservation
    return unless avion.present? && avion.grounded?

    errors.add(:avion, 'est indisponible pour maintenance (potentiel épuisé ou visite expirée).')
  end
end
