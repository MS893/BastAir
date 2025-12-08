# config/schedule.rb

# Learn more: http://github.com/javan/whenever

# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end

# Définit le chemin du fichier de log pour les tâches cron.
set :output, "log/cron.log"

# Exécute la tâche Rake tous les jours à 4h du matin.
every 1.day, at: '4:00 am' do
  rake "validity:check_and_notify"
end

# Archive les anciens événements Google Calendar le 1er de chaque mois à 5h du matin
# every 1.month, at: '5:00 am' do
#  rake "calendar:archive_old_events"
# end
