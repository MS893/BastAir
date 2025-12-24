class Avion < ApplicationRecord
  has_many :reservations, dependent: :destroy
  has_many :vols, dependent: :destroy
  has_many :signalements, dependent: :destroy

  # Document CEN scanné
  has_one_attached :cen_document
  validates :cen_document, content_type: { in: 'application/pdf', message: 'doit être un format PDF' },
              size: { less_than: 5.megabytes, message: 'doit peser moins de 5 Mo' }

  # Réinitialise le compteur pour la visite des 100 heures
  def reset_potential_100h!
    update!(next_100h: 100.0)
  end

  # Réinitialise le potentiel moteur (ex: après changement moteur ou RG)
  def reset_potential_engine!
    update!(potentiel_moteur: 2000.0)
  end

  # Valide la visite annuelle (repart pour 1 an à partir d'aujourd'hui)
  def reset_potential_annuelle!
    update!(annuelle: Date.today + 1.year)
  end

  # Valide le CEN (repart pour 1 an à partir d'aujourd'hui)
  def reset_potential_cen!
    update!(cert_examen_navigabilite: Date.today + 1.year)
  end

  # Vérifie si l'avion est indisponible (maintenance requise ou documents expirés)
  def grounded?
    potentiel_moteur <= 0 ||
      (next_100h.present? && next_100h <= 0) ||
      (annuelle.present? && annuelle < Date.today) ||
      (cert_examen_navigabilite.present? && cert_examen_navigabilite < Date.today)
  end

  # Notifie les pilotes ayant une réservation future si l'avion est indisponible
  def notify_future_reservations
    reservations.where("start_time > ?", Time.current).find_each do |reservation|
      ReservationMailer.aircraft_grounded_alert(reservation).deliver_later
    end
  end
end
