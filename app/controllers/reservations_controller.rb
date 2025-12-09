require 'google/apis/calendar_v3'
require 'googleauth'

class ReservationsController < ApplicationController
  before_action :set_reservation, only: [:edit, :update, :destroy]
  before_action :authenticate_user!
  before_action :check_user_balance, only: [:new, :create]
  before_action :check_user_validities, only: [:new, :create]

  def new
    @reservation = Reservation.new(avion_id: Avion.order(:immatriculation).first&.id)
    # On charge les données nécessaires pour les listes déroulantes du formulaire
    @avions = Avion.order(:immatriculation)
    @instructeurs = User.where("fi IS NOT NULL AND fi >= ?", Date.today).order(:nom)
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
      # On recharge les données pour que le formulaire puisse se ré-afficher avec les erreurs
      @avions = Avion.all
      @instructeurs = User.where("fi IS NOT NULL AND fi >= ?", Date.today).order(:nom)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @reservation est chargé par le before_action
    # On charge les données pour les listes déroulantes
    @avions = Avion.all
    @instructeurs = User.where("fi IS NOT NULL AND fi >= ?", Date.today).order(:nom)
    
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
  
      # --- Vérifier si l'instruction a été désactivée ---
      if old_instruction && !@reservation.instruction? && old_instructor_event_id.present?
        # L'instruction a été retirée : supprimer l'événement de l'agenda de l'instructeur
        Rails.logger.info "🔍 DEBUG: Instruction retirée, suppression de l'événement instructeur"
        Rails.logger.info "🔍 DEBUG: old_fi=#{old_fi}, old_instructor_event_id=#{old_instructor_event_id}"
        calendar_service.delete_instructor_event_by_id(old_fi, old_instructor_event_id)
        @reservation.update(google_instructor_event_id: nil)
      elsif old_instruction && @reservation.instruction? && old_fi != @reservation.fi
        # L'instructeur a changé
        if old_fi.present? && old_instructor_event_id.present?
          Rails.logger.info "🔍 DEBUG: Instructeur changé, suppression de l'ancien événement"
          calendar_service.delete_instructor_event_by_id(old_fi, old_instructor_event_id)
        end
        # Créer le nouvel événement instructeur
        if @reservation.fi.present?
          Rails.logger.info "🔍 DEBUG: Création du nouvel événement instructeur"
          calendar_service.create_instructor_event(@reservation)
        end
      end
  
      # --- Synchronisation avec Google Calendar pour l'événement avion ---
      calendar_service.update_event_for_app(@reservation)

      redirect_to params[:redirect_to].presence || root_path, notice: 'Votre réservation a été mise à jour avec succès.'

    else
      @avions = Avion.all
      @instructeurs = User.where("fi IS NOT NULL AND fi >= ?", Date.today).order(:nom)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # --- Règle de gestion : Annulation impossible moins de 24h avant le vol (sauf pour les admins) ---
    if @reservation.start_time < 24.hours.from_now && !current_user.admin?
      # --- Envoi de l'email de notification aux administrateurs ---
      admins = User.where(admin: true)
      admins.each do |admin|
        UserMailer.late_cancellation_attempt_notification(admin, current_user, @reservation).deliver_later
      end

      redirect_to root_path, alert: "Annulation impossible : la réservation commence dans moins de 24 heures. Veuillez contacter un administrateur ou un instructeur pour annuler cette réservation."
      return
    end

    # --- Synchronisation de la suppression avec Google Calendar ---
    calendar_service = GoogleCalendarService.new

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
    params.require(:reservation).permit(:avion_id, :start_time, :end_time, :summary, :instruction, :fi, :type_vol, :start_date, :start_hour, :start_minute, :end_date, :end_hour, :end_minute)
  end
  
end
