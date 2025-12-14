class ProgressionsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_access, only: [:show]

  def show
    if current_user.instructeur?
      # Pour les instructeurs, on liste les élèves pour la sélection.
      # On exclut les comptes BIA qui ne sont pas des élèves pilotes.
      @eleves = User.where("LOWER(fonction) = ?", 'eleve').where.not("LOWER(prenom) = ?", 'bia').order(:nom, :prenom)

      # Si un élève est sélectionné via les paramètres, on le charge.
      if params[:eleve_id].present?
        @selected_eleve = User.find(params[:eleve_id])
      end
    else
      # Pour un élève, on affiche directement son propre livret.
      @selected_eleve = current_user
    end

    # Si un élève est sélectionné, on charge ses leçons de vol.
    @flight_lessons = @selected_eleve.flight_lessons.order(:date) if @selected_eleve
  end
  


  private

  def authorize_access
    # Seuls les élèves et les instructeurs peuvent accéder à cette page.
    redirect_to root_path, alert: "Vous n'avez pas l'autorisation d'accéder à cette page." unless current_user.eleve? || current_user.instructeur? || current_user.admin?
  end
  
end
