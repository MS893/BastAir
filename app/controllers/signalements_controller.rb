class SignalementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_avion

  def new
    @signalement = @avion.signalements.new
  end

  def create
    @signalement = @avion.signalements.new(signalement_params)
    @signalement.user = current_user # Associe l'utilisateur qui signale

    respond_to do |format|
      if @signalement.save
        # Envoyer un email à l'admin/mécanicien ***************************************************************************************** à faire
        
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

  def set_avion
    @avion = Avion.find(params[:avion_id])
  end

  def signalement_params
    params.require(:signalement).permit(:description)
    # Le statut et l'urgence ne sont pas dans le formulaire simple,
    # ils gardent leur valeur par défaut.
  end
end
