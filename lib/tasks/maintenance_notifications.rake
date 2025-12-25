# frozen_string_literal: true

namespace :maintenance do
  desc 'Vérifie les échéances CEN et envoie des alertes si expiration < 30 jours'
  task check_cen: :environment do
    puts 'Vérification des échéances CEN...'

    # On cherche les avions dont le CEN expire dans les 30 prochains jours (et qui n'est pas déjà périmé depuis longtemps si on veut, ici on prend tout ce qui est < 30 jours futur)
    threshold_date = 30.days.from_now.to_date

    Avion.where.not(cert_examen_navigabilite: nil).where(
      'cert_examen_navigabilite <= ? AND cert_examen_navigabilite >= ?', threshold_date, Date.today
    ).find_each do |avion|
      puts "  -> Envoi alerte CEN pour #{avion.immatriculation} (Expiration : #{avion.cert_examen_navigabilite})"
      MaintenanceMailer.cen_alert(avion).deliver_now
    end

    puts 'Vérification terminée.'
  end

  desc 'Vérifie les avions indisponibles et prévient les pilotes ayant réservé'
  task notify_grounded_reservations: :environment do
    puts 'Vérification des réservations sur avions indisponibles...'
    Avion.all.each do |avion|
      avion.notify_future_reservations if avion.grounded?
    end
  end
end
