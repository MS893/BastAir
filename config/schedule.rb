# frozen_string_literal: true

# config/schedule.rb

# Définit l'environnement (par défaut 'production', mais s'adapte si vous êtes en dev)
set :environment, ENV['RAILS_ENV'] || 'development'

# Redirige les logs (très utile pour déboguer si la tâche ne se lance pas)
set :output, 'log/cron.log'

# Tâche de vérification du CEN (tous les jours à 8h00 : envoi d'email si CEN expire dans les 30 jours)
# attention : cela ne fonctionnera que si l'ordinateur est allumé à 8h00 !!!
every 1.day, at: '8:00 am' do
  rake 'maintenance:check_cen'
end

# Vérifie les réservations sur avions indisponibles et prévient les pilotes (tous les jours à 8h30)
every 1.day, at: '8:30 am' do
  rake 'maintenance:notify_grounded_reservations'
end

# Bonus : Tâche de vérification des qualifications instructeurs (tous les jours à 9h00)
# (Basé sur votre fichier lib/tasks/instructor_notifications.rake)
every 1.day, at: '9:00 am' do
  rake 'instructors:notify_expiring_fi'
end

# ATTENTION
# Si vous hébergez votre site sur Heroku, whenever ne fonctionnera pas car le système de fichiers est éphémère.
# Vous devrez utiliser l'add-on gratuit Heroku Scheduler et ajouter la commande rake maintenance:check_cen via leur interface web.
# Après avoir modifié ce fichier, n'oubliez pas de mettre à jour la crontab avec la commande :
#   whenever --update-crontab
# Vous pouvez vérifier les tâches planifiées avec (terminal) :
#   crontab -l
# Pour plus d'informations, consultez la documentation de la gem 'whenever' : https://github.com/javan/whenever
