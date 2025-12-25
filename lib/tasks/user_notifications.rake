# frozen_string_literal: true

# lib/tasks/user_notifications.rake

namespace :users do
  desc 'Envoie un e-mail de rappel pour les licences et visites médicales expirant dans moins de 30 jours.'
  task notify_expiring_validities: :environment do
    puts 'Vérification des validités (licences, médical) expirant bientôt...'

    thirty_days_from_now = Date.today + 30.days

    # --- Licences ---
    # On exclut les comptes BIA des notifications
    expiring_licenses = User.where.not(prenom: 'bia').where(date_licence: Date.today..thirty_days_from_now)
    if expiring_licenses.any?
      puts "Envoi de notifications pour #{expiring_licenses.count} licence(s) expirant bientôt..."
      expiring_licenses.each do |user|
        UserMailer.validity_reminder_email(user, 'votre licence', user.date_licence).deliver_later
        puts "- Notification de licence envoyée à #{user.email}"
      end
    end

    # --- Visites Médicales ---
    # On exclut les comptes BIA des notifications
    expiring_medicals = User.where.not(prenom: 'bia').where(medical: Date.today..thirty_days_from_now)
    if expiring_medicals.any?
      puts "Envoi de notifications pour #{expiring_medicals.count} visite(s) médicale(s) expirant bientôt..."
      expiring_medicals.each do |user|
        UserMailer.validity_reminder_email(user, 'votre visite médicale', user.medical).deliver_later
        puts "- Notification de visite médicale envoyée à #{user.email}"
      end
    end

    puts 'Vérification des validités terminée.'
  end
end
