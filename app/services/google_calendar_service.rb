# frozen_string_literal: true

class GoogleCalendarService
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

  def initialize
    credentials_path = ENV.fetch('GOOGLE_APPLICATION_CREDENTIALS', nil)

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

    return unless event_data && calendar_ids.any?

    # --- Création de l'événement principal (avion) ---
    main_calendar_id = calendar_ids.first # Le premier ID est toujours celui de l'avion
    main_event = Google::Apis::CalendarV3::Event.new(**event_data)

    begin
      result = @service.insert_event(main_calendar_id, main_event)
      record.update(google_event_id: result.id) if record.respond_to?(:google_event_id)
      Rails.logger.info "[GoogleCalendarService] Événement principal créé (ID: #{result.id}) dans le calendrier #{main_calendar_id}."

      # --- Création de l'événement pour l'instructeur (si nécessaire) ---
      if record.is_a?(Reservation) && record.instruction? && record.fi.present?
        # On récupère l'objet User de l'instructeur à partir de son nom stocké dans `record.fi`.
        instructor_name = record.fi

        instructor_calendar_id = get_instructor_calendar_id(instructor_name)

        if instructor_calendar_id.present?

          # On personnalise le titre pour l'instructeur
          instructor_event_data = event_data.merge(
            summary: "Instruction avec #{record.user.name}"
          )
          instructor_event = Google::Apis::CalendarV3::Event.new(**instructor_event_data)

          begin
            instructor_result = @service.insert_event(instructor_calendar_id, instructor_event)
            Rails.logger.info "[GoogleCalendarService] Événement instructeur créé (ID: #{instructor_result.id}) dans le calendrier #{instructor_calendar_id}."
            # On sauvegarde l'ID de l'événement de l'instructeur dans la réservation.
            record.update(google_instructor_event_id: instructor_result.id)
          rescue Google::Apis::Error => e
            Rails.logger.error "[GoogleCalendarService] Erreur lors de la création de l'événement instructeur : #{e.message}"
          end
        else
          Rails.logger.warn "[GoogleCalendarService] Aucun agenda trouvé pour l'instructeur '#{instructor_name}'. L'événement n'a pas été créé."
        end
      end
    rescue Google::Apis::Error => e
      Rails.logger.error "[GoogleCalendarService] ERREUR lors de la création de l'événement principal : #{e.message}. Calendrier tenté : #{main_calendar_id}"
    end
  end

  # Méthode pour mettre à jour un événement existant sur Google Calendar
  def update_event_for_app(record)
    # On ne traite que les réservations pour cette logique complexe
    return unless record.is_a?(Reservation)

    # --- 1. Mise à jour de l'événement principal (avion) ---
    main_event_id = record.google_event_id
    if main_event_id.present?
      main_calendar_id = get_calendar_ids_for_reservation(record).first
      event_data = build_event_from_reservation(record)
      main_event = Google::Apis::CalendarV3::Event.new(**event_data)

      begin
        @service.update_event(main_calendar_id, main_event_id, main_event)
        Rails.logger.info "[GoogleCalendarService] Événement principal (ID: #{main_event_id}) mis à jour avec succès."
      rescue Google::Apis::Error => e
        Rails.logger.error "[GoogleCalendarService] Erreur lors de la mise à jour de l'événement principal : #{e.message}"
      end
    end

    # --- 2. Mise à jour de l'événement de l'instructeur ---
    instructor_event_id = record.google_instructor_event_id
    return if instructor_event_id.blank?

    instructor_name = record.fi
    instructor_calendar_id = get_instructor_calendar_id(instructor_name)
    return if instructor_calendar_id.blank?

    # On personnalise le titre pour l'instructeur
    instructor_event_data = build_event_from_reservation(record).merge(
      summary: "Instruction avec #{record.user.name}"
    )
    instructor_event = Google::Apis::CalendarV3::Event.new(**instructor_event_data)

    begin
      @service.update_event(instructor_calendar_id, instructor_event_id, instructor_event)
      Rails.logger.info "[GoogleCalendarService] Événement instructeur (ID: #{instructor_event_id}) mis à jour avec succès."
    rescue Google::Apis::Error => e
      Rails.logger.error "[GoogleCalendarService] Erreur lors de la mise à jour de l'événement instructeur : #{e.message}"
    end
  end

  # Méthode pour supprimer un événement existant sur Google Calendar
  # Cette méthode est maintenant dédiée à la suppression de l'événement principal (avion).
  def delete_event_for_app(record, _event_id: nil)
    google_event_id = record.google_event_id
    return if google_event_id.blank?

    calendar_id = nil
    if record.is_a?(Reservation)
      # On récupère uniquement l'agenda de l'avion F-HGBT
      avion = record.avion
      calendar_id = case avion.immatriculation
                    when 'F-HGBT'
                      ENV.fetch('GOOGLE_CALENDAR_ID_AVION_F_HGBT', nil)
                    when 'F-HGCU'
                      ENV.fetch('GOOGLE_CALENDAR_ID_AVION_F_HGCU', nil)
                    else
                      ENV.fetch('GOOGLE_CALENDAR_ID', nil)
                    end
    elsif record.is_a?(Event)
      calendar_id = ENV.fetch('GOOGLE_CALENDAR_ID_EVENTS', nil)
    end

    return unless calendar_id

    begin
      @service.delete_event(calendar_id, google_event_id)
      Rails.logger.info "[GoogleCalendarService] Événement principal (ID: #{google_event_id}) supprimé avec succès du calendrier #{calendar_id}."
    rescue Google::Apis::ClientError => e
      # Si l'événement n'est pas trouvé (déjà supprimé), on ne lève pas d'erreur.
      if [404, 410].include?(e.status_code)
        Rails.logger.info "INFO: L'événement Google Calendar #{google_event_id} n'a pas été trouvé sur le calendrier #{calendar_id}. Il a probablement déjà été supprimé."
      else
        # Pour les autres erreurs (ex: problème de permission), on affiche le message.
        Rails.logger.error "ERREUR lors de la suppression de l'événement Google Calendar : #{e.message}"
        Rails.logger.error "[GoogleCalendarService] Erreur API lors de la suppression de l'événement principal pour #{record.class} ##{record.id}: #{e.message}"
      end
    end
  end

  def create_instructor_event_only(reservation)
    # This method is specifically for creating an instructor event when one is added to an existing reservation.
    return unless reservation.instruction? && reservation.fi.present?

    # 1. Find the instructor's calendar ID using the existing pattern.
    instructor_name = reservation.fi
    instructor_calendar_id = get_instructor_calendar_id(instructor_name)
    return if instructor_calendar_id.blank?

    # 2. Build the event data using the existing reservation helper, then customize the summary.
    event_data = build_event_from_reservation(reservation).merge(
      summary: "Instruction avec #{reservation.user.name}"
    )
    instructor_event = Google::Apis::CalendarV3::Event.new(**event_data)

    begin
      # 3. Insert the event and update the reservation record with the new event ID.
      created_event = @service.insert_event(instructor_calendar_id, instructor_event)
      reservation.update_column(:google_instructor_event_id, created_event.id)
      Rails.logger.info "✅ Événement instructeur créé avec succès : #{created_event.id}"
    rescue Google::Apis::ClientError => e
      Rails.logger.error "💥 Erreur lors de la création de l'événement instructeur : #{e.message}"
    end
  end

  # Récupère la liste de tous les calendriers accessibles par le compte de service
  def list_calendars
    # On récupère les IDs des calendriers de base depuis les variables d'environnement
    calendar_ids = [
      ENV.fetch('GOOGLE_CALENDAR_ID', nil),
      ENV.fetch('GOOGLE_CALENDAR_ID_EVENTS', nil),
      ENV.fetch('GOOGLE_CALENDAR_ID_AVION_F_HGBT', nil),
      ENV.fetch('GOOGLE_CALENDAR_ID_AVION_F_HGCU', nil)
    ]
    # On y ajoute dynamiquement les IDs des calendriers de tous les instructeurs depuis la base de données
    calendar_ids += User.where.not(google_calendar_id: nil).pluck(:google_calendar_id)
    calendar_ids = calendar_ids.compact.uniq

    # Pour chaque ID, on récupère les détails du calendrier (nom, etc.)
    calendar_ids.map do |cal_id|
      # On utilise get_calendar, qui récupère un calendrier par son ID, et non get_calendar_list.
      @service.get_calendar(cal_id)
    end
  end

  # Supprime tous les événements d'un calendrier spécifique
  def clear_calendar(calendar_id)
    raise "L'ID du calendrier ne peut pas être vide." if calendar_id.blank?

    Rails.logger.info "INFO: Début de la suppression de tous les événements du calendrier #{calendar_id}."
    page_token = nil
    begin
      loop do
        response = @service.list_events(calendar_id, page_token: page_token)
        response.items.each do |event|
          @service.delete_event(calendar_id, event.id)
          Rails.logger.info "  - Événement supprimé : #{event.summary} (ID: #{event.id})"
          puts "  > Événement supprimé : #{event.summary}"
          sleep 0.5 # Pause pour éviter le Rate Limit lors de la suppression en masse
        end
        page_token = response.next_page_token
        break unless page_token
      end
    rescue Google::Apis::Error => e
      raise "Erreur lors de la communication avec l'API Google : #{e.message}"
    end
    Rails.logger.info "INFO: Tous les événements du calendrier #{calendar_id} ont été supprimés."
  end

  # Archive old events in a specific calendar by changing their title and color
  def archive_old_events(calendar_id, older_than_date)
    raise 'Calendar ID cannot be blank.' if calendar_id.blank?
    raise 'Cutoff date must be a valid date.' unless older_than_date.is_a?(Time) || older_than_date.is_a?(Date)

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
          Rails.logger.info "  - Archived event: #{event.summary}"
        end
        page_token = response.next_page_token
        break unless page_token
      end
    rescue Google::Apis::Error => e
      raise "Error communicating with Google API: #{e.message}"
    end
    archived_count
  end

  # Supprime l'événement de l'instructeur en utilisant l'ID stocké dans la réservation.
  def delete_instructor_event(reservation)
    # On vérifie qu'il y a bien un ID d'événement instructeur à supprimer.
    instructor_event_id = reservation.google_instructor_event_id
    return if instructor_event_id.blank?

    # On récupère le nom de l'instructeur pour trouver son agenda.
    instructor_name = reservation.fi
    return if instructor_name.blank?

    # On utilise la même table de correspondance que pour la création.
    instructor_calendar_id = get_instructor_calendar_id(instructor_name)
    return if instructor_calendar_id.blank?

    begin
      @service.delete_event(instructor_calendar_id, instructor_event_id)
      Rails.logger.info "[GoogleCalendarService] Événement instructeur (ID: #{instructor_event_id}) supprimé avec succès du calendrier #{instructor_calendar_id}."
    rescue Google::Apis::ClientError => e
      if [404, 410].include?(e.status_code)
        Rails.logger.warn "[GoogleCalendarService] Événement instructeur (ID: #{instructor_event_id}) non trouvé. Il a probablement déjà été supprimé."
      else
        Rails.logger.error "[GoogleCalendarService] Erreur API lors de la suppression de l'événement instructeur pour la réservation ##{reservation.id}: #{e.message}"
      end
    end
  end

  # Supprime l'événement de l'instructeur en utilisant le nom et l'ID stocké
  def delete_instructor_event_by_id(instructor_name, instructor_event_id)
    Rails.logger.info "🔍 [GoogleCalendarService] delete_instructor_event_by_id called with: instructor_name=#{instructor_name}, event_id=#{instructor_event_id}"

    return false unless instructor_event_id.present? && instructor_name.present?

    # On utilise la même table de correspondance que pour la création
    instructor_calendar_id = get_instructor_calendar_id(instructor_name)
    return false if instructor_calendar_id.blank?

    Rails.logger.info "🔍 [GoogleCalendarService] Tentative suppression event #{instructor_event_id} du calendrier #{instructor_calendar_id}"

    begin
      @service.delete_event(instructor_calendar_id, instructor_event_id)
      Rails.logger.info "[GoogleCalendarService] ✅ Événement instructeur (ID: #{instructor_event_id}) supprimé avec succès du calendrier #{instructor_calendar_id}."
      true
    rescue Google::Apis::ClientError => e
      if [404, 410].include?(e.status_code)
        Rails.logger.warn "[GoogleCalendarService] ⚠️ Événement instructeur (ID: #{instructor_event_id}) non trouvé. Il a probablement déjà été supprimé."
        true
      else
        Rails.logger.error "[GoogleCalendarService] ❌ Erreur API lors de la suppression de l'événement instructeur (status #{e.status_code}): #{e.message}"
        false
      end
    rescue StandardError => e
      Rails.logger.error "[GoogleCalendarService] ❌ Erreur inattendue: #{e.class}: #{e.message}"
      false
    end
  end

  # Nouvelle méthode dédiée à la mise à jour d'un événement (modèle Event) sur Google Calendar
  def update_google_event_for_app_event(app_event)
    google_event_id = app_event.google_event_id
    calendar_id = ENV.fetch('GOOGLE_CALENDAR_ID_EVENTS', nil)

    # On ne fait rien si l'ID de l'événement ou du calendrier est manquant
    return unless google_event_id.present? && calendar_id.present?

    # On construit les nouvelles données de l'événement à partir de l'objet mis à jour
    event_data = build_event_from_app_event(app_event)
    event = Google::Apis::CalendarV3::Event.new(**event_data)

    begin
      @service.update_event(calendar_id, google_event_id, event)
      Rails.logger.info "[GoogleCalendarService] Événement (ID: #{google_event_id}) mis à jour avec succès dans le calendrier #{calendar_id}."
    rescue Google::Apis::ClientError => e
      Rails.logger.error "[GoogleCalendarService] Erreur API lors de la mise à jour de l'événement pour Event ##{app_event.id}: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "[GoogleCalendarService] Erreur inattendue lors de la mise à jour de l'événement pour Event ##{app_event.id}: #{e.class}: #{e.message}"
    end
  end

  # Nouvelle méthode dédiée à la suppression d'un événement (modèle Event) de Google Calendar
  def delete_google_event_for_app_event(app_event)
    google_event_id = app_event.google_event_id
    calendar_id = ENV.fetch('GOOGLE_CALENDAR_ID_EVENTS', nil)

    # On ne fait rien si l'ID de l'événement ou du calendrier est manquant
    return unless google_event_id.present? && calendar_id.present?

    begin
      @service.delete_event(calendar_id, google_event_id)
      Rails.logger.info "[GoogleCalendarService] Événement (ID: #{google_event_id}) supprimé avec succès du calendrier #{calendar_id}."
    rescue Google::Apis::ClientError => e
      # Si l'événement n'est pas trouvé (code 404 ou 410), c'est qu'il a déjà été supprimé. On ne lève pas d'erreur.
      if [404, 410].include?(e.status_code)
        Rails.logger.warn "[GoogleCalendarService] L'événement Google Calendar #{google_event_id} n'a pas été trouvé. Il a probablement déjà été supprimé."
      else
        # Pour toute autre erreur API, on la journalise.
        Rails.logger.error "[GoogleCalendarService] Erreur API lors de la suppression de l'événement pour Event ##{app_event.id}: #{e.message}"
      end
    end
  end

  private

  # Centralise la recherche de l'ID de calendrier d'un instructeur par son nom.
  def get_instructor_calendar_id(instructor_name)
    return nil if instructor_name.blank?

    # On décompose le nom complet (ex: "Christian HUY") pour chercher sur les bonnes colonnes.
    first_name, last_name = instructor_name.split(' ', 2)
    # Gère le cas où le nom n'est pas complet
    return nil unless first_name && last_name

    # On cherche l'utilisateur et on retourne son ID de calendrier Google.
    instructor = User.find_by(prenom: first_name, nom: last_name)
    instructor&.google_calendar_id
  end

  # Cette méthode retourne un tableau d'IDs de calendriers pertinents pour la réservation.
  def get_calendar_ids_for_reservation(reservation)
    ids = []
    avion_calendar_id = nil

    # On cherche d'abord un agenda spécifique à l'avion.
    avion = reservation.avion
    case avion.immatriculation
    when 'F-HGBT'
      avion_calendar_id = ENV.fetch('GOOGLE_CALENDAR_ID_AVION_F_HGBT', nil)
    when 'F-HGCU'
      avion_calendar_id = ENV.fetch('GOOGLE_CALENDAR_ID_AVION_F_HGCU', nil)
      # Ajoutez d'autres cas pour d'autres avions ici.
    end

    # On ajoute l'agenda de l'avion s'il a été trouvé, sinon on utilise l'agenda principal par défaut.
    ids << (avion_calendar_id || ENV.fetch('GOOGLE_CALENDAR_ID', nil))

    # NOTE: La logique de récupération de l'agenda de l'instructeur est maintenant gérée
    # directement dans la méthode `create_event_for_app` pour plus de clarté.
    # Nous n'ajoutons plus l'ID de l'agenda de l'instructeur ici.

    ids.compact.uniq # Retourne les IDs uniques et non nuls
  end

  # Construit le hash de données pour un événement Google à partir d'une Réservation
  def build_event_from_reservation(reservation)
    # Le summary doit inclure l'immatriculation de l'avion et le nom/prénom du user
    summary_text = "#{reservation.user.name} / #{reservation.avion.immatriculation}"

    description_text = "Réservation de vol\n"
    description_text += "Pilote : #{reservation.user.name}\n"
    description_text += "Avion : #{reservation.avion.immatriculation}\n"
    description_text += "Type de vol : #{reservation.type_vol}\n"

    if reservation.instruction? && reservation.fi.present?
      # On décompose le nom complet (ex: "Christian HUY") pour chercher sur les bonnes colonnes.
      first_name, last_name = reservation.fi.split(' ', 2)
      instructeur = User.find_by(prenom: first_name, nom: last_name)
      description_text += "Instructeur : #{instructeur.name}\n" if instructeur
    end

    # On récupère le fuseau horaire depuis les paramètres de l'application.
    # On utilise 'Europe/Paris' comme valeur de secours si le paramètre n'existe pas encore.
    time_zone = Setting.find_by(var: 'time_zone')&.val || 'Europe/Paris'

    # On formate les dates en ISO8601 mais SANS l'indicateur de fuseau horaire ('Z').
    # C'est la clé pour que Google Calendar utilise le `time_zone` que nous lui fournissons.
    start_time_str = reservation.start_time.strftime('%Y-%m-%dT%H:%M:%S')
    end_time_str = reservation.end_time.strftime('%Y-%m-%dT%H:%M:%S')

    {
      summary: summary_text,
      description: description_text,
      start: { date_time: start_time_str, time_zone: time_zone },
      end: { date_time: end_time_str, time_zone: time_zone }
    }
  end

  # Construit le hash de données pour un événement Google à partir d'un Event de l'app
  def build_event_from_app_event(app_event)
    # Calcule l'heure de fin en se basant sur la durée textuelle
    start_time = app_event.start_date.to_time
    end_time = start_time # On initialise l'heure de fin à l'heure de début
    duration_str = app_event.duration.to_s.downcase

    # On extrait les heures et les minutes de la chaîne de durée (ex: "3h30")
    hours = duration_str.match(/(\d+)\s*h/i)&.captures&.first.to_i
    minutes = duration_str.match(/(\d+)\s*min/i)&.captures&.first.to_i

    # Gère le cas "3h30"
    minutes += 30 if duration_str.include?('h30')

    end_time += hours.hours if hours.positive?
    end_time += minutes.minutes if minutes.positive?

    # Si aucune durée n'a pu être calculée (ex: "Journée"), on met une durée par défaut de 1h.
    end_time = start_time + 1.hour if end_time == start_time

    # On récupère le fuseau horaire configuré dans l'application.
    time_zone = Setting.find_by(var: 'time_zone')&.val || 'Europe/Paris'

    # On formate les dates SANS l'indicateur de fuseau horaire ('Z')
    # pour que Google Calendar utilise le `time_zone` que nous lui fournissons.
    start_time_str = start_time.strftime('%Y-%m-%dT%H:%M:%S')
    end_time_str = end_time.strftime('%Y-%m-%dT%H:%M:%S')

    {
      summary: app_event.title,
      description: app_event.description,
      start: { date_time: start_time_str, time_zone: time_zone },
      end: { date_time: end_time_str, time_zone: time_zone }
    }
  end
end
