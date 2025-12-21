require 'google/apis/calendar_v3'
require 'googleauth'

class ReservationsController < ApplicationController
  before_action :set_reservation, only: [:edit, :update, :destroy]
  before_action :authenticate_user!
  before_action :check_user_balance, only: [:new, :create]
  before_action :check_user_validities, only: [:new, :create]

  def index
    # On récupère les réservations à venir de l'utilisateur, paginées
    @upcoming_reservations = current_user.reservations.where('start_time >= ?', Time.current).order(start_time: :asc).page(params[:upcoming_page]).per(10)

    # On récupère les réservations passées de l'utilisateur, paginées
    @past_reservations = current_user.reservations.where('start_time < ?', Time.current).order(start_time: :desc).page(params[:past_page]).per(10)
  end

  def new
    @reservation = Reservation.new(avion_id: Avion.order(:immatriculation).first&.id)

    # On charge les données nécessaires pour les listes déroulantes du formulaire
    @avions = Avion.order(:immatriculation)
    @instructeurs = available_instructors(Date.today, 7, 0) # Valeurs par défaut
  end

  def create
    @reservation = current_user.reservations.build(reservation_params)

    # Combiner les champs date/heure en timestamps
    if params[:reservation][:start_date].present? && params[:reservation][:start_hour].present?
      start_datetime = "#{params[:reservation][:start_date]} #{params[:reservation][:start_hour]}:#{params[:reservation][:start_minute]}:00"
      @reservation.start_time = DateTime.parse(start_datetime)
    end

    if params[:reservation][:end_date].present? && params[:reservation][:end_hour].present?
      end_datetime = "#{params[:reservation][:end_date]} #{params[:reservation][:end_hour]}:#{params[:reservation][:end_minute]}:00"
      @reservation.end_time = DateTime.parse(end_datetime)
    end
    @avions = Avion.order(:immatriculation)
    @instructeurs = User.where("fi IS NOT NULL AND fi >= ?", Date.today).order(:nom)

    # On pré-remplit le titre de l'événement avec l'immatriculation de l'avion
    if @reservation.avion_id.present?
      avion = Avion.find_by(id: @reservation.avion_id)
      @reservation.summary = "Réservation #{avion.immatriculation}" if avion.present?
    end

    if @reservation.save
      # --- Synchronisation avec Google Calendar ---
      # On instancie le service (qui s'authentifie via le compte de service) et on crée l'événement.
      GoogleCalendarService.new.create_event_for_app(@reservation)

      redirect_to root_path, notice: 'Votre réservation a été créée avec succès.'
    else
      # On recharge les données pour que le formulaire puisse se réafficher avec les erreurs
      @avions = Avion.all
      if @reservation.start_time
        @instructeurs = available_instructors(@reservation.start_time.to_date, @reservation.start_time.hour, @reservation.start_time.min)
      else
        @instructeurs = available_instructors(Date.today, 7, 0)
      end
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @reservation est chargé par le before_action
    # On charge les données pour les listes déroulantes
    @avions = Avion.all
    @instructeurs = available_instructors(@reservation.start_time.to_date, @reservation.start_time.hour, @reservation.start_time.min)
    
    # Décomposer start_time et end_time pour le formulaire
    if @reservation.start_time.present?
      @reservation.start_date = @reservation.start_time.to_date
      @reservation.start_hour = @reservation.start_time.hour
      @reservation.start_minute = @reservation.start_time.min
    end
    
    if @reservation.end_time.present?
      @reservation.end_date = @reservation.end_time.to_date
      @reservation.end_hour = @reservation.end_time.hour
      @reservation.end_minute = @reservation.end_time.min
    end
  end

  def update
    # Garder trace de l'ancien instructeur ET de l'event_id instructeur
    old_fi = @reservation.fi
    old_instruction = @reservation.instruction?
    old_instructor_event_id = @reservation.google_instructor_event_id
    
    # Combiner les champs date/heure en timestamps
    if params[:reservation][:start_date].present? && params[:reservation][:start_hour].present?
      start_datetime = "#{params[:reservation][:start_date]} #{params[:reservation][:start_hour]}:#{params[:reservation][:start_minute]}:00"
      params[:reservation][:start_time] = DateTime.parse(start_datetime)
    end
    
    if params[:reservation][:end_date].present? && params[:reservation][:end_hour].present?
      end_datetime = "#{params[:reservation][:end_date]} #{params[:reservation][:end_hour]}:#{params[:reservation][:end_minute]}:00"
      params[:reservation][:end_time] = DateTime.parse(end_datetime)
    end
    
    if @reservation.update(reservation_params)
      calendar_service = GoogleCalendarService.new
  
      # --- Logique de synchronisation Google Calendar ---

      if old_instruction && !@reservation.instruction? && old_instructor_event_id.present?
        # L'instruction a été retirée : supprimer l'événement de l'agenda de l'instructeur
        Rails.logger.info "🔍 DEBUG: Instruction retirée, suppression de l'événement instructeur"
        calendar_service.delete_instructor_event_by_id(old_fi, old_instructor_event_id)
        @reservation.update(google_instructor_event_id: nil)
        calendar_service.update_event_for_app(@reservation) # On met à jour l'event avion (ex: description)

      elsif old_instruction && @reservation.instruction? && old_fi != @reservation.fi
        # Cas 2: L'instructeur a changé
        if old_fi.present? && old_instructor_event_id.present?
          Rails.logger.info "🔍 DEBUG: Instructeur changé, suppression de l'ancien événement"
          calendar_service.delete_instructor_event_by_id(old_fi, old_instructor_event_id)
        end
        calendar_service.create_instructor_event_only(@reservation) if @reservation.fi.present?
        calendar_service.update_event_for_app(@reservation) # On met à jour l'event avion

      elsif !old_instruction && @reservation.instruction? && @reservation.fi.present?
        # Cas 3: L'instruction vient d'être ajoutée
        Rails.logger.info "🔍 DEBUG: Instruction ajoutée, création de l'événement instructeur"
        calendar_service.create_instructor_event_only(@reservation)
        calendar_service.update_event_for_app(@reservation) # On met à jour l'event avion
      else
        # Cas 4: Autre mise à jour (heure, etc.)
        calendar_service.update_event_for_app(@reservation)
      end

      redirect_to params[:redirect_to].presence || root_path, notice: 'Votre réservation a été mise à jour avec succès.'

    else
      @avions = Avion.all
      if @reservation.start_time
        @instructeurs = available_instructors(@reservation.start_time.to_date, @reservation.start_time.hour, @reservation.start_time.min)
      else
        @instructeurs = available_instructors(Date.today, 7, 0)
      end
      render :edit, status: :unprocessable_entity
    end

  end

  def destroy
    # Début de la transaction pour s'assurer que tout est annulé si une partie échoue
    calendar_service = GoogleCalendarService.new
    time_before_flight = @reservation.start_time - Time.current
    cancellation_reason = params[:cancellation_reason]
    penalty_amount = 0
    
    # --- Gestion des annulations tardives ---
    # On récupère les seuils de pénalité depuis le cache pour optimiser.
    # Le cache expirera après 1 heure, ou lorsque les paramètres seront modifiés.
    penalty_settings = Rails.cache.fetch('penalty_settings', expires_in: 1.hour) do
      settings_hash = Setting.where("var LIKE 'penalty_%'").pluck(:var, :val).to_h
      (1..3).map do |i|
        delay = settings_hash["penalty_delay_#{i}"].to_i
        amount = settings_hash["penalty_amount_#{i}"].to_i
        delay > 0 && amount > 0 ? { delay: delay, amount: amount } : nil
      end.compact.sort_by { |h| h[:delay] } # On trie par délai (12h, 24h, 48h)
    end
    
    # On trouve le premier seuil qui correspond
    applicable_penalty = penalty_settings.find { |p| time_before_flight < p[:delay].hours }
    
    if applicable_penalty
      # 1. Déterminer le montant de la pénalité
      penalty_amount = applicable_penalty[:amount]
      # On vérifie que l'annulation a lieu dans la fenêtre de temps de la plus grande pénalité
      # (ex: si les délais sont 12, 24, 48, on crée une pénalité si l'annulation est à moins de 48h)
      if time_before_flight < penalty_settings.last[:delay].hours
        # 2. Créer un enregistrement dans la table des pénalités
        penalite = Penalite.new(
            user: @reservation.user,
            avion_immatriculation: @reservation.avion.immatriculation,
            reservation_start_time: @reservation.start_time,
            reservation_end_time: @reservation.end_time,
            instructor_name: @reservation.fi,
            cancellation_reason: cancellation_reason,
            penalty_amount: penalty_amount,
            status: 'En attente'
        )
        unless penalite.save
          Rails.logger.error "ERREUR lors de la création de la pénalité : #{penalite.errors.full_messages.to_sentence}"
        end
  
        # 3. Envoyer les emails de notification
        admins = User.where(admin: true)
        admins.each do |admin|
          UserMailer.late_cancellation_notification(admin, current_user, @reservation, cancellation_reason).deliver_later
        end
  
        # Envoi de l'email à l'instructeur si le vol était en instruction
        if @reservation.instruction? && @reservation.fi.present?
          first_name, last_name = @reservation.fi.split(' ', 2)
          instructor = User.find_by(prenom: first_name, nom: last_name)
          if instructor
            UserMailer.late_cancellation_notification_to_instructor(instructor, current_user, @reservation, cancellation_reason).deliver_later
          end
        end
      end
    end

    # --- Suppression de la réservation et des événements du calendrier ---

    # 1. Si c'est un vol en instruction, on supprime aussi l'événement de l'agenda de l'instructeur.
    if @reservation.instruction? && @reservation.fi.present?
      Rails.logger.info "Tentative de suppression de l'événement de l'instructeur pour la réservation ##{@reservation.id}..."
      calendar_service.delete_instructor_event(@reservation)
    end

    # 2. On supprime l'événement principal de l'agenda de l'avion.
    Rails.logger.info "Tentative de suppression de l'événement principal (avion) pour la réservation ##{@reservation.id}..."
    calendar_service.delete_event_for_app(@reservation)

    # --- Envoi de l'email de confirmation d'annulation ---
    UserMailer.reservation_cancelled_notification(current_user, @reservation).deliver_later

    # On supprime la réservation de la base de données
    @reservation.destroy

    redirect_to root_path, notice: 'Votre réservation a été annulée avec succès.', status: :see_other
  end

  # Méthode pour récupérer les instructeurs disponibles en fonction de la date et de l'heure
  def available_instructors(date, hour, minute)
    # Convertir les paramètres en Time
    start_time = Time.zone.local(date.year, date.month, date.day, hour, minute)

    # Déterminer le jour et la période de la réservation
    reservation_day = start_time.strftime('%A').downcase # ex: "monday"

    # Les jours en base sont en français (ex: "lundi")
    day_translation = { "monday" => "lundi", "tuesday" => "mardi", "wednesday" => "mercredi", "thursday" => "jeudi", "friday" => "vendredi", "saturday" => "samedi", "sunday" => "dimanche" }
    reservation_day_fr = day_translation[reservation_day]

    # Définir les périodes possibles en fonction de l'heure de début
    # Matin: jusqu'à 13h
    # Après-midi: à partir de 12h
    possible_periods = []
    possible_periods << 'matin' if start_time.hour <= 13
    possible_periods << 'apres-midi' if start_time.hour >= 12

    # Récupérer les IDs des instructeurs disponibles
    available_instructor_ids = InstructorAvailability.where(day: reservation_day_fr, period: possible_periods).pluck(:user_id).uniq

    # Récupérer les instructeurs disponibles
    instructors = User.where(id: available_instructor_ids).where("fi IS NOT NULL AND fi >= ?", Date.today).order(:nom)

    return instructors
  end

  def fetch_available_instructors
    date = params[:date].present? ? Date.parse(params[:date]) : Date.today
    hour = params[:hour].present? ? params[:hour].to_i : 7
    minute = params[:minute].present? ? params[:minute].to_i : 0

    @instructeurs = available_instructors(date, hour, minute)
    render partial: 'reservations/instructor_options', locals: { instructeurs: @instructeurs }
  end

  def agenda
    # affichage des différents agendas
    Rails.logger.info("=== ACTION AGENDA APPELÉE ===")
    scope = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY

    # initialisation des credentials (service account)
    key_env = ENV['GOOGLE_APPLICATION_CREDENTIALS']
    keyfile = key_env.present? ? Rails.root.join(key_env) : Rails.root.join('config', 'gcal-service-account.json')
    Rails.logger.info("Keyfile path: #{keyfile} / exists: #{File.exist?(keyfile)}")

    unless File.exist?(keyfile)
      Rails.logger.error("Fichier de clé introuvable: #{keyfile}")
      @calendar_ids = []
      flash.now[:alert] = "Clé Google introuvable côté serveur."
      return
    end

    begin
      sa_creds = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: File.open(keyfile), scope: scope)
      sa_creds.fetch_access_token!
      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = sa_creds

      # 1) Essai : liste des calendars accessibles
      clist = service.list_calendar_lists
      Rails.logger.info("calendar_list.items.count = #{clist.items.size}")
      clist.items.each { |c| Rails.logger.info("Found (list): #{c.summary} | #{c.id}") }

      if clist.items.any?
        @calendar_ids = clist.items.map(&:id)
        return
      end

      # 2) Fallback : tenter d'accéder directement aux IDs connus (depuis .env)
      candidates = [
        ENV['GOOGLE_CALENDAR_ID'],
        ENV['GOOGLE_CALENDAR_ID_EVENTS'],
        ENV['GOOGLE_CALENDAR_ID_AVION_F_HGBT'],
        ENV['GOOGLE_CALENDAR_ID_INSTRUCTEUR_HUY']
      ].compact.uniq

      Rails.logger.info("Trying explicit calendar ids: #{candidates.inspect}")
      found = []

      candidates.each do |cid|
        begin
          cal = service.get_calendar(cid)
          Rails.logger.info("GET calendar success: #{cal.summary} | #{cal.id}")
          found << cal.id

          # lister les ACL pour diagnostic
          begin
            acls = service.list_acl(cid)
            acls.items.each do |acl|
              Rails.logger.info("ACL #{cid}: scope=#{acl.scope&.type}/#{acl.scope&.value} role=#{acl.role}")
            end
          rescue => e
            Rails.logger.error("Cannot list ACL for #{cid}: #{e.class}: #{e.message}")
          end

        rescue Google::Apis::ClientError => e
          Rails.logger.error("GET calendar #{cid} failed (ClientError): #{e.message}")
        rescue Google::Apis::AuthorizationError => e
          Rails.logger.error("GET calendar #{cid} failed (AuthorizationError): #{e.message}")
        rescue => e
          Rails.logger.error("GET calendar #{cid} failed (Other): #{e.class}: #{e.message}")
        end
      end

      @calendar_ids = found
      if @calendar_ids.empty?
        flash.now[:alert] = "Aucun agenda accessible. Vérifiez le partage avec #{sa_creds.issuer || 'le service account'} et les permissions."
      end

    rescue => e
      Rails.logger.error("[Google Calendar] #{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      @calendar_ids = []
      flash.now[:alert] = "Erreur lors de la connexion à l'API Google Calendar."
    end

  end



  
  private

  def set_reservation
    if current_user.admin?
      @reservation = Reservation.find(params[:id])
    else
      @reservation = current_user.reservations.find(params[:id])
    end
  end

  # vérifie si l'adhérent a un solde positif ou pas
  def check_user_balance
    if current_user.solde <= 0
      flash[:alert] = "Votre solde est négatif ou nul. Veuillez créditer votre compte avant de pouvoir réserver un vol."
      redirect_to credit_path
    end
  end

  # vérifie les dates butées
  def check_user_validities
    user = current_user
    expired_items = []

    if user.date_licence.present? && user.date_licence < Date.today
      expired_items << "votre licence"
    end

    if user.medical.present? && user.medical < Date.today
      expired_items << "votre visite médicale"
    end

    if user.controle.present? && user.controle < Date.today
      expired_items << "votre contrôle en vol"
    end

    if expired_items.any?
      flash[:alert] = "Vous ne pouvez pas réserver de vol car #{expired_items.to_sentence(last_word_connector: ' et ')} a expiré."
      redirect_to root_path, status: :see_other
    end
  end

  def reservation_params
    params.require(:reservation).permit(:avion_id, :start_time, :end_time, :summary, :instruction, :fi, :type_vol, :start_date, :start_hour, :start_minute, :end_date, :end_hour, :end_minute, :cancellation_reason)
  end
  
end
