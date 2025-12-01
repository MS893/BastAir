class GoogleCalendarService
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

  def initialize
    credentials_path = ENV['GOOGLE_APPLICATION_CREDENTIALS']

    # On vérifie que la variable d'environnement est définie et que le fichier existe.
    unless credentials_path.present? && File.exist?(credentials_path)
      # Si ce n'est pas le cas, on lève une erreur explicite pour faciliter le débogage.
      raise "La variable d'environnement GOOGLE_APPLICATION_CREDENTIALS n'est pas définie ou le fichier de clé est introuvable. Veuillez vérifier votre fichier .env et redémarrer le serveur."
    end

    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(credentials_path),
      scope: SCOPE
    )
  end

  def create_event(reservation)
    # Cette méthode est maintenant un alias pour la nouvelle méthode plus générique
    create_event_for_app(reservation)
  end

  # Méthode principale qui gère la création d'événements pour différents types d'objets
  def create_event_for_app(record)
    calendar_ids = []
    event_data = nil

    case record
    when Reservation
      calendar_ids = get_calendar_ids_for_reservation(record)
      event_data = build_event_from_reservation(record)
    when Event
      calendar_ids << ENV['GOOGLE_CALENDAR_ID_EVENTS'] if ENV['GOOGLE_CALENDAR_ID_EVENTS'].present?
      event_data = build_event_from_app_event(record)
    end

    return unless event_data
    return if calendar_ids.empty?

    calendar_ids.compact! # S'assurer qu'il n'y a pas d'IDs de calendrier nuls

    # On crée un objet Event vide, puis on lui assigne les attributs
    # pour éviter les conflits de nommage avec le modèle Event de l'application.
    event = Google::Apis::CalendarV3::Event.new
    event.update!(**event_data)

    begin
      # Pour chaque calendrier pertinent, on insère l'événement
      calendar_ids.each do |cal_id|
        result = @service.insert_event(cal_id, event)
        # Note: Si plusieurs événements sont créés, seul le dernier google_event_id sera stocké
        # dans le champ `google_event_id` de la réservation. Si vous avez besoin de suivre
        # tous les IDs d'événements créés, le modèle Reservation devrait avoir un tableau d'IDs.
        record.update(google_event_id: result.id) if record.respond_to?(:google_event_id)
        puts "DEBUG: Événement Google Calendar créé avec succès dans le calendrier #{cal_id}. ID : #{result.id}"
      end
    rescue Google::Apis::Error => e
      puts "ERREUR lors de la création de l'événement Google Calendar : #{e.message}. Calendriers tentés : #{calendar_ids.join(', ')}"
    end
  end

  
  private

  # Cette méthode retourne un tableau d'IDs de calendriers pertinents pour la réservation.
  def get_calendar_ids_for_reservation(reservation)
    ids = []

    # Ajout de l'agenda principal par défaut (acb.bastair@gmail.com)
    ids << ENV['GOOGLE_CALENDAR_ID'] if ENV['GOOGLE_CALENDAR_ID'].present?

    # Ajout de l'agenda de l'avion si l'immatriculation correspond
    avion = reservation.avion
    case avion.immatriculation
    when "F-HGBT"
      ids << ENV['GOOGLE_CALENDAR_ID_AVION_F_HGBT'] if ENV['GOOGLE_CALENDAR_ID_AVION_F_HGBT'].present?
    # Ajoutez d'autres cas pour les avions ici si nécessaire
    end

    # Ajout de l'agenda de l'instructeur si 'fi' est présent et correspond
    # Le champ 'fi' contient l'ID de l'utilisateur instructeur.
    if reservation.fi.present? && (instructeur = User.find_by(id: reservation.fi))
      # On utilise le nom de famille de l'instructeur pour la comparaison.
      # Assurez-vous que le nom correspond à ce que vous attendez (ex: "HUY").
      case instructeur.nom 
      when "HUY" # Remplacez "HUY" par le nom de famille exact de l'instructeur si nécessaire.
        ids << ENV['GOOGLE_CALENDAR_ID_INSTRUCTEUR_HUY']
      # Ajoutez d'autres cas pour les instructeurs ici si nécessaire
      end
    end

    ids.compact.uniq # Retourne les IDs uniques et non nuls
  end

  # Construit le hash de données pour un événement Google à partir d'une Réservation
  def build_event_from_reservation(reservation)
    {
      summary: reservation.summary,
      description: "Réservé par : #{reservation.user.name}\nType de vol : #{reservation.type_vol}",
      start: { date_time: reservation.start_time.iso8601 },
      end: { date_time: reservation.end_time.iso8601 }
    }
  end

  # Construit le hash de données pour un événement Google à partir d'un Event de l'app
  def build_event_from_app_event(app_event)
    # Calcule l'heure de fin en se basant sur la durée textuelle
    end_time = app_event.start_date
    duration_in_hours = app_event.duration.to_i
    end_time += duration_in_hours.hours if duration_in_hours > 0

    # Cas particulier pour les durées non numériques
    end_time += 30.minutes if app_event.duration.include?('30')

    {
      summary: app_event.title,
      description: app_event.description,
      start: { date_time: app_event.start_date.iso8601 },
      end: { date_time: end_time.iso8601 }
    }
  end
end