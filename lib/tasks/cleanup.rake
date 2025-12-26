# frozen_string_literal: true

namespace :cleanup do
  desc "Supprime les événements passés, à l'exception de ceux intitulés 'Objets trouvés'."
  task events: :environment do
    puts 'Début de la tâche de nettoyage des événements...'

    # On sélectionne les événements à supprimer :
    # - Dont la date de début est antérieure à aujourd'hui.
    # - Dont le titre n'est PAS "Objets trouvés".
    events_to_delete = Event.where(start_date: ...Time.zone.now.beginning_of_day).where.not(title: 'Objets trouvés')

    if events_to_delete.any?
      puts "Suppression de #{events_to_delete.count} événement(s) passé(s)."
      events_to_delete.destroy_all # Utiliser destroy_all pour déclencher les callbacks (ex: suppression associée)
    else
      puts 'Aucun événement à supprimer.'
    end
    puts 'Tâche de nettoyage des événements terminée.'
  end
end
