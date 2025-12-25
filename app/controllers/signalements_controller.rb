class SignalementsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_instructor_or_admin!, only: [:edit, :update, :destroy]
  # On ne cherche l'avion que pour les actions `new` et `create`
  before_action :set_avion, only: [:create]
  before_action :set_signalement, only: [:show, :edit, :update, :destroy]

  def index
    # Pour le formulaire de filtre
    @avions = Avion.order(:immatriculation)

    # Base de la requête
    @signalements = Signalement.includes(:user, :avion)

    # Application des filtres s'ils sont présents dans les paramètres
    if params[:by_status].present?
      @signalements = @signalements.where(status: params[:by_status])
    end
    if params[:by_avion].present?
      @signalements = @signalements.where(avion_id: params[:by_avion])
      @selected_avion = Avion.find(params[:by_avion])
      @signalement = @selected_avion.signalements.new # Pour la modale de création
    end

    # Tri et pagination sur la collection filtrée
    @signalements = @signalements.order(created_at: :desc).page(params[:page]).per(10)
  end

  def show
    # @signalement est chargé par le before_action
  end

  def edit
    # @signalement est chargé par le before_action
    # La vue edit.html.erb sera rendue implicitement
  end

  def update
    if @signalement.update(signalement_update_params)
      redirect_to signalements_path, notice: 'Le statut du signalement a été mis à jour avec succès.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    Rails.logger.info("Suppression - admin: #{current_user.admin?}, signalement: #{@signalement.id}")
    @signalement.destroy
    redirect_to signalements_path, notice: 'Le signalement a été supprimé avec succès.', status: :see_other
  end

  def create
    @signalement = @avion.signalements.new(signalement_params)
    @signalement.user = current_user # Associe l'utilisateur qui signale

    respond_to do |format|
      if @signalement.save
        # --- Envoi de l'email de notification ---
        # On récupère tous les administrateurs et le président
        recipients = User.where(admin: true).or(User.where(fonction: 'president'))
        # On envoie l'email à chaque destinataire
        recipients.each { |recipient| SignalementMailer.new_signalement_notification(recipient, @signalement).deliver_later }

        # Si la requête est HTML (formulaire classique), on redirige
        format.html { redirect_to signalements_path, notice: "Le signalement sur l'avion #{@avion.immatriculation} a été enregistré avec succès." }
        # Si la requête est JSON (AJAX), on renvoie une réponse JSON de succès.
        format.json { render json: { status: 'success', message: 'Signalement enregistré.' }, status: :created }
      else
        # En cas d'échec, on redirige vers la page d'index avec un message d'erreur
        error_message = @signalement.errors.full_messages.to_sentence.presence || "Une erreur est survenue."
        format.html { redirect_to signalements_path(by_avion: @avion.id), alert: "Le signalement n'a pas pu être créé : #{error_message}" }
        format.json { render json: @signalement.errors, status: :unprocessable_entity }
      end
    end
  end

  
  private

  def set_signalement
    @signalement = Signalement.find(params[:id])
  end

  def set_avion
    @avion = Avion.find(params[:avion_id])
  end

  def signalement_params
    params.require(:signalement).permit(:description)
  end

  # On utilise une méthode de "strong parameters" distincte pour la mise à jour
  # afin de n'autoriser que la modification du statut.
  def signalement_update_params
    params.require(:signalement).permit(:status)
  end
  
end
