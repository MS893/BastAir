class SignalementsController < ApplicationController
  before_action :authenticate_user!
  # On ne cherche l'avion que pour les actions `new` et `create`
  before_action :set_avion, only: [:new, :create]
  before_action :set_signalement, only: [:show, :edit, :update]
  before_action :authorize_admin!, only: [:edit, :update]

  def new
    @signalement = @avion.signalements.new
  end

  def index
    # Pour le formulaire de filtre
    @avions = Avion.order(:immatriculation)

    # Base de la requête
    @signalements = Signalement.includes(:user, :avion)

    # Application des filtres s'ils sont présents dans les paramètres
    @signalements = @signalements.where(status: params[:by_status]) if params[:by_status].present?
    @signalements = @signalements.where(avion_id: params[:by_avion]) if params[:by_avion].present?

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

  def create
    @signalement = @avion.signalements.new(signalement_params)
    @signalement.user = current_user # Associe l'utilisateur qui signale

    respond_to do |format|
      if @signalement.save
        # --- Envoi de l'email de notification ---
        # On récupère tous les administrateurs et le président
        recipients = User.where(admin: true).or(User.where(fonction: 'president'))
        # On envoie l'email à chaque destinataire
        recipients.each do |recipient|
          SignalementMailer.new_signalement_notification(recipient, @signalement).deliver_later
          send_push_notification(recipient, @signalement)
        end

        # Si la requête est HTML (formulaire classique), on redirige.
        format.html { redirect_to root_path, notice: "Le signalement sur l'avion #{@avion.immatriculation} a été enregistré avec succès. Merci." }
        # Si la requête est JSON (AJAX), on renvoie une réponse JSON de succès.
        format.json { render json: { status: 'success', message: 'Signalement enregistré.' }, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
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

  # Méthode privée pour envoyer les notifications Push
  def send_push_notification(user, signalement)
    # On ne fait rien si l'utilisateur n'a pas d'abonnement aux notifications
    return if user.web_push_subscriptions.empty?

    # On prépare le contenu de la notification
    message = {
      title: "Nouveau Signalement sur #{signalement.avion.immatriculation}",
      options: {
        body: "Signalé par #{signalement.user.full_name}: \"#{signalement.description.truncate(100)}\"",
        icon: view_context.image_path('icons/icon-192x192.png'),
        badge: view_context.image_path('icons/icon-192x192.png'),
        data: { path: signalements_url } # URL où rediriger l'utilisateur au clic
      }
    }

    # On envoie la notification à tous les navigateurs abonnés de l'utilisateur
    user.web_push_subscriptions.each do |subscription|
      WebPush.payload_send(
        message: JSON.generate(message),
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh,
        auth: subscription.auth,
        vapid: { public_key: Rails.application.credentials.dig(:web_push, :public_key), private_key: Rails.application.credentials.dig(:web_push, :private_key) }
      )
    end
  rescue WebPush::InvalidSubscription => e
    # Si un abonnement est invalide (ex: l'utilisateur a révoqué la permission), on le supprime.
    puts "Abonnement invalide pour l'utilisateur #{user.id}, suppression : #{e.message}"
    subscription.destroy
  end
end
