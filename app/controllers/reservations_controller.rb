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
    # On rassemble tous les IDs des calendriers à afficher dans un tableau.
    # .compact retirera les valeurs nil si une variable d'environnement n'est pas définie.
    @calendar_ids = [
      ENV['GOOGLE_CALENDAR_ID'], # L'agenda principal
      ENV['GOOGLE_CALENDAR_ID_AVION_F_HGBT'],
      ENV['GOOGLE_CALENDAR_ID_INSTRUCTEUR_HUY']
    ].compact
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
