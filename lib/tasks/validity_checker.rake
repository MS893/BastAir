# frozen_string_literal: true

namespace :validity do
  desc 'Vérifie les validités des utilisateurs expirant dans 60, 30 et 7 jours et envoie des e-mails de rappel.'
  task check_and_notify: :environment do
    puts 'Vérification des validités expirant dans 60, 30, et 7 jours...'
    reminder_intervals = [60, 30, 7]
    validity_fields = {
      date_licence: 'votre licence',
      medical: 'votre visite médicale',
      controle: 'votre contrôle en vol'
    }

    # Vérifie les butées (licence, médical, contrôle)
    reminder_intervals.each do |days|
      puts "Vérification des validités expirant dans #{days} jours..."
      target_date = Date.today + days.days

      validity_fields.each do |field, item_name|
        # Trouve les utilisateurs dont la validité expire exactement à la date cible
        User.where(field => target_date).each do |user|
          # Envoie l'e-mail de rappel
          UserMailer.validity_reminder_email(user, item_name, user.public_send(field)).deliver_later
          puts "Rappel de #{days} jours envoyé à #{user.email} pour l'expiration de #{item_name}."
        end
      end
    end

    puts 'Vérification terminée.'
  end
end
