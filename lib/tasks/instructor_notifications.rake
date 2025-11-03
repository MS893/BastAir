# lib/tasks/instructor_notifications.rake

namespace :instructors do
  desc "Envoie un e-mail de rappel aux instructeurs dont la qualification FI expire dans moins de 30 jours."
  task notify_expiring_fi: :environment do
    puts "Vérification des qualifications d'instructeur expirant bientôt..."

    # Définir la période de recherche : entre aujourd'hui et dans 30 jours
    start_date = Date.today
    end_date = Date.today + 30.days

    # Trouver tous les utilisateurs dont la date 'fi' est dans cet intervalle
    expiring_instructors = User.where(fi: start_date..end_date)

    if expiring_instructors.empty?
      puts "Aucune qualification d'instructeur n'expire dans les 30 prochains jours."
    else
      puts "Envoi de notifications à #{expiring_instructors.count} instructeur(s)..."
      expiring_instructors.each do |instructor|
        # Utilise le mailer existant pour envoyer la notification
        UserMailer.validity_reminder_email(instructor, "votre qualification d'instructeur (FI)", instructor.fi).deliver_later
        puts "- Notification envoyée à #{instructor.email} (expiration le #{instructor.fi.strftime('%d/%m/%Y')})"
      end

      # Envoi d'un e-mail de résumé à tous les administrateurs
      admins = User.where(admin: true)
      if admins.any?
        puts "Envoi du résumé aux administrateurs..."
        UserMailer.expiring_fi_summary(admins, expiring_instructors).deliver_later
      end
    end

    puts "Vérification terminée."
  end
end
