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
    # Cette méthode est un alias
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

  # Méthode pour mettre à jour un événement existant sur Google Calendar
  def update_event_for_app(record)
    # On s'assure que l'enregistrement a bien un ID d'événement Google
    google_event_id = record.google_event_id
    return unless google_event_id.present?

    calendar_ids = []
    event_data = nil

    case record
    when Reservation
      calendar_ids = get_calendar_ids_for_reservation(record)
      event_data = build_event_from_reservation(record)
    when Event
      calendar_ids << ENV['GOOGLE_CALENDAR_ID_EVENTS']
      event_data = build_event_from_app_event(record)
    end

    return if calendar_ids.empty? || event_data.nil?

    event = Google::Apis::CalendarV3::Event.new(**event_data)

    begin
      # On met à jour l'événement sur chaque calendrier où il a été créé
      calendar_ids.each do |cal_id|
        @service.update_event(cal_id, google_event_id, event)
        puts "DEBUG: Événement Google Calendar mis à jour avec succès dans le calendrier #{cal_id}. ID : #{google_event_id}"
      end
    rescue Google::Apis::Error => e
      puts "ERREUR lors de la mise à jour de l'événement Google Calendar : #{e.message}"
    end
  end

  # Méthode pour supprimer un événement existant sur Google Calendar
  def delete_event_for_app(record)
    google_event_id = record.google_event_id
    return unless google_event_id.present?

    calendar_ids = []
    case record
    when Reservation
      calendar_ids = get_calendar_ids_for_reservation(record)
    when Event
      calendar_ids << ENV['GOOGLE_CALENDAR_ID_EVENTS']
    end

    return if calendar_ids.empty?

    begin
      calendar_ids.each do |cal_id|
        @service.delete_event(cal_id, google_event_id)
        puts "DEBUG: Événement Google Calendar supprimé avec succès du calendrier #{cal_id}. ID : #{google_event_id}"
      end
    rescue Google::Apis::ClientError => e
      # Si l'événement n'est pas trouvé (déjà supprimé), on ne lève pas d'erreur.
      if e.status_code == 404 || e.status_code == 410
        puts "INFO: L'événement Google Calendar #{google_event_id} n'a pas été trouvé sur le calendrier #{calendar_ids.join(', ')}. Il a probablement déjà été supprimé."
      else
        # Pour les autres erreurs (ex: problème de permission), on affiche le message.
        puts "ERREUR lors de la suppression de l'événement Google Calendar : #{e.message}"
      end
    end
  end

  # Récupère la liste de tous les calendriers accessibles par le compte de service
  def list_calendars
    # On récupère les IDs des calendriers depuis les variables d'environnement
    calendar_ids = [
      ENV['GOOGLE_CALENDAR_ID'],
      ENV['GOOGLE_CALENDAR_ID_EVENTS'],
      ENV['GOOGLE_CALENDAR_ID_AVION_F_HGBT'],
      ENV['GOOGLE_CALENDAR_ID_INSTRUCTEUR_HUY']
    ].compact.uniq

    # Pour chaque ID, on récupère les détails du calendrier (nom, etc.)
    calendar_ids.map do |cal_id|
      # On utilise get_calendar, qui récupère un calendrier par son ID, et non get_calendar_list.
      @service.get_calendar(cal_id)
    end
  end

  # Supprime tous les événements d'un calendrier spécifique
  def clear_calendar(calendar_id)
    raise "L'ID du calendrier ne peut pas être vide." if calendar_id.blank?

    puts "INFO: Début de la suppression de tous les événements du calendrier #{calendar_id}."
    page_token = nil
    begin
      loop do
        response = @service.list_events(calendar_id, page_token: page_token)
        response.items.each do |event|
          @service.delete_event(calendar_id, event.id)
          puts "  - Événement supprimé : #{event.summary} (ID: #{event.id})"
        end
        page_token = response.next_page_token
        break unless page_token
      end
    rescue Google::Apis::Error => e
      raise "Erreur lors de la communication avec l'API Google : #{e.message}"
    end
    puts "INFO: Tous les événements du calendrier #{calendar_id} ont été supprimés."
  end

  # Archive old events in a specific calendar by changing their title and color
  def archive_old_events(calendar_id, older_than_date)
    raise "Calendar ID cannot be blank." if calendar_id.blank?
    raise "Cutoff date must be a valid date." unless older_than_date.is_a?(Time) || older_than_date.is_a?(Date)

    archived_count = 0
    page_token = nil
    
    # The time must be in RFC3339 format for the API
    time_max = older_than_date.to_datetime.rfc3339

    begin
      loop do
        # Fetch events that end before the cutoff date
        response = @service.list_events(
          calendar_id,
          page_token: page_token,
          time_max: time_max,
          single_events: true, # Expands recurring events into single instances
          order_by: 'startTime'
        )

        response.items.each do |event|
          # Skip if already archived
          next if event.summary&.start_with?('[ARCHIVÉ]')

          event.summary = "[ARCHIVÉ] #{event.summary}"
          event.color_id = '8' # '8' corresponds to gray in Google Calendar
          @service.update_event(calendar_id, event.id, event)
          archived_count += 1
          puts "  - Archived event: #{event.summary}"
        end
        page_token = response.next_page_token
        break unless page_token
      end
    rescue Google::Apis::Error => e
      raise "Error communicating with Google API: #{e.message}"
    end
    archived_count
  end

  
  private

  # Cette méthode retourne un tableau d'IDs de calendriers pertinents pour la réservation.
  def get_calendar_ids_for_reservation(reservation)
    ids = []
    avion_calendar_id = nil
    
    # On cherche d'abord un agenda spécifique à l'avion.
    avion = reservation.avion
    case avion.immatriculation
    when "F-HGBT"
      avion_calendar_id = ENV['GOOGLE_CALENDAR_ID_AVION_F_HGBT']
    # Ajoutez d'autres cas pour d'autres avions ici.
    end

    # On ajoute l'agenda de l'avion s'il a été trouvé, sinon on utilise l'agenda principal par défaut.
    ids << (avion_calendar_id || ENV['GOOGLE_CALENDAR_ID'])

    # Ajout de l'agenda de l'instructeur si le vol est en instruction.
    if reservation.instruction? && reservation.fi.present? && (instructeur = User.find_by(id: reservation.fi))
      # La logique pour trouver l'agenda de l'instructeur peut être affinée ici.
      # Pour l'instant, on se base sur le nom de famille.
      ids << ENV['GOOGLE_CALENDAR_ID_INSTRUCTEUR_HUY'] if instructeur.nom == "HUY"
    end

    ids.compact.uniq # Retourne les IDs uniques et non nuls
  end

  # Construit le hash de données pour un événement Google à partir d'une Réservation
  def build_event_from_reservation(reservation)
    # Le summary doit inclure l'immatriculation de l'avion et le nom/prénom du user
    summary_text = "#{reservation.user.name} - #{reservation.avion.immatriculation}"
    
    description_text = "Réservation de vol\n"
    description_text += "Pilote : #{reservation.user.name}\n"
    description_text += "Avion : #{reservation.avion.immatriculation}\n"
    description_text += "Type de vol : #{reservation.type_vol}\n"
    
    if reservation.instruction? && reservation.fi.present?
      instructeur = User.find_by(id: reservation.fi)
      description_text += "Instructeur : #{instructeur.name}\n" if instructeur
    end

    {
      summary: summary_text,
      description: description_text,
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
