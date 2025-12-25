# frozen_string_literal: true

class Avion < ApplicationRecord
  has_many :reservations, dependent: :destroy
  has_many :vols, dependent: :destroy
  has_many :signalements, dependent: :destroy

  # Document CEN scanné
  has_one_attached :cen_document
  validates :cen_document, content_type: { in: 'application/pdf', message: 'doit être un format PDF' },
                           size: { less_than: 5.megabytes, message: 'doit peser moins de 5 Mo' }
  validates :tbo_helice, presence: true
  validates :tbo_parachute, presence: true
  validates :immatriculation, presence: true, uniqueness: true
  validates :marque, presence: true
  validates :modele, presence: true
  validates :moteur, presence: true
  validates :conso_horaire, presence: true, numericality: { only_integer: true, greater_than: 10 }
  validate :tbo_helice_must_be_in_the_future
  validate :tbo_parachute_must_be_in_the_future
  validate :_1000h_must_be_in_the_future

  # Réinitialise le compteur pour la visite des 50 heures
  def reset_potential_50h!
    update_attribute(:next_50h, 50.0)
  end

  # Réinitialise le compteur pour la visite des 100 heures
  def reset_potential_100h!
    update_attribute(:next_100h, 100.0)
  end

  # Réinitialise le compteur pour la visite des 1000 heures
  def reset_potential_1000h!
    update_attribute(:next_1000h, 1000.0)
  end

  # Réinitialise le potentiel moteur (ex: après changement moteur ou RG)
  def reset_potential_engine!
    update_attribute(:potentiel_moteur, 2000.0)
  end

  # Valide la visite annuelle (repart pour 1 an à partir d'aujourd'hui)
  def reset_potential_annuelle!
    update_attribute(:annuelle, Date.today + 1.year)
  end

  # Valide le CEN (repart pour 1 an à partir d'aujourd'hui)
  def reset_potential_cen!
    update_attribute(:cert_examen_navigabilite, Date.today + 1.year)
  end

  # Vérifie si l'avion est indisponible (maintenance requise ou documents expirés)
  def grounded?
    potentiel_moteur <= 0 ||
      (next_50h.present? && next_50h <= 0) ||
      (next_100h.present? && next_100h <= 0) ||
      (next_1000h.present? && next_1000h <= 0) ||
      (annuelle.present? && annuelle < Date.today) ||
      (cert_examen_navigabilite.present? && cert_examen_navigabilite < Date.today)
  end

  # Notifie les pilotes ayant une réservation future si l'avion est indisponible
  def notify_future_reservations
    reservations.where('start_time > ?', Time.current).find_each do |reservation|
      ReservationMailer.aircraft_grounded_alert(reservation).deliver_later
    end
  end

  private

  def tbo_helice_must_be_in_the_future
    return unless tbo_helice_changed? && tbo_helice.present? && tbo_helice <= Date.today

    errors.add(:tbo_helice, 'doit être dans le futur')
  end

  def tbo_parachute_must_be_in_the_future
    return unless tbo_parachute_changed? && tbo_parachute.present? && tbo_parachute <= Date.today

    errors.add(:tbo_parachute, 'doit être dans le futur')
  end

  def _1000h_must_be_in_the_future
    return unless _1000h_changed? && _1000h.present? && _1000h <= Date.today

    errors.add(:_1000h, 'doit être dans le futur')
  end
end
