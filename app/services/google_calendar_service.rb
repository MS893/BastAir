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
    calendar_id, event_data = case record
                              when Reservation
                                [get_calendar_id_for_reservation(record), build_event_from_reservation(record)]
                              when Event
                                [ENV['GOOGLE_CALENDAR_ID_EVENTS'], build_event_from_app_event(record)]
                              else
                                [nil, nil]
                              end

    return unless calendar_id

    return unless event_data

    # On crée un objet Event vide, puis on lui assigne les attributs
    # pour éviter les conflits de nommage avec le modèle Event de l'application.
    event = Google::Apis::CalendarV3::Event.new
    event.update!(**event_data)

    begin
      result = @service.insert_event(calendar_id, event)
      # On met à jour l'enregistrement avec l'ID de l'événement Google si la colonne existe
      record.update(google_event_id: result.id) if record.respond_to?(:google_event_id)
      puts "DEBUG: Événement Google Calendar créé avec succès. ID : #{result.id}"
    rescue Google::Apis::Error => e
      puts "ERREUR lors de la création de l'événement Google Calendar : #{e.message}"
    end
  end

  
  private

  # Cette méthode choisit le bon ID de calendrier en fonction de l'avion réservé.
  # Vous devrez l'adapter à votre logique.
  def get_calendar_id_for_reservation(reservation)
    avion = reservation.avion
    case avion.immatriculation
    when "F-HGBT"
      ENV['GOOGLE_CALENDAR_ID_AVION_F_HGBT']
    # autres avions ici
    when "HUY"
      ENV['GOOGLE_CALENDAR_ID_INSTRUCTEUR_HUY']
    # autres instructeurs ici
    else
      puts "AVERTISSEMENT: Aucun ID de calendrier trouvé pour l'avion #{avion.immatriculation}"
      nil
    end
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