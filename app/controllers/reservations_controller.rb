require 'google/apis/calendar_v3'
require 'googleauth'

class ReservationsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_user_balance, only: [:new, :create]
  before_action :check_user_validities, only: [:new, :create]

  def new
    @reservation = Reservation.new
    # On charge les données nécessaires pour les listes déroulantes du formulaire
    @avions = Avion.all
    @instructeurs = User.where("fi IS NOT NULL AND fi >= ?", Date.today).order(:nom)
  end

  def create
    @reservation = current_user.reservations.build(reservation_params)

    # On pré-remplit le titre de l'événement avec l'immatriculation de l'avion
    @reservation.summary = "Réservation #{Avion.find(@reservation.avion_id).immatriculation}" if @reservation.avion_id.present?

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
    params.require(:reservation).permit(:avion_id, :start_time, :end_time, :summary, :instruction, :fi, :type_vol)
  end
end
