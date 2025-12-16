class ProgressionsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_access, only: [:show]
  before_action :authorize_student_area!

  def show
    if current_user.instructeur? || current_user.admin?
      # Pour les instructeurs, on liste les élèves pour la sélection.
      # On exclut les comptes BIA qui ne sont pas des élèves pilotes.
      @eleves = User.where("LOWER(fonction) = ?", 'eleve').where.not("LOWER(prenom) = ?", 'bia').order(:nom, :prenom)

      # Si un élève est sélectionné via les paramètres, on le charge.
      if params[:eleve_id].present?
        @selected_eleve = User.find(params[:eleve_id])
        user_livrets = Livret.where(user: @selected_eleve)
      end
    else
      # Pour un élève, on affiche directement son propre livret.
      @selected_eleve = current_user
      user_livrets = Livret.where(user: current_user)
    end

    if user_livrets
      @examens_theoriques = user_livrets.where(course_id: nil, flight_lesson_id: nil).order(:id)
      @formations_theoriques = user_livrets.where.not(course_id: nil).order(:id)
      @lecons_en_vol = user_livrets.where.not(flight_lesson_id: nil).order(:id)
    else
      @examens_theoriques = Livret.none
      @formations_theoriques = Livret.none
      @lecons_en_vol = Livret.none
    end
  end
  
  def download
    if params[:eleve_id].present? && (current_user.instructeur? || current_user.admin?)
      @selected_eleve = User.find(params[:eleve_id])
    else
      @selected_eleve = current_user
    end

    # On définit @eleves pour que le formulaire dans la vue ne cause pas d'erreur, même s'il n'est pas affiché dans le PDF.
    @eleves = User.where("LOWER(fonction) = ?", 'eleve').where.not("LOWER(prenom) = ?", 'bia').order(:nom, :prenom)

    user_livrets = Livret.where(user: @selected_eleve)
    @examens_theoriques = user_livrets.where(course_id: nil, flight_lesson_id: nil).order(:id)
    @formations_theoriques = user_livrets.where.not(course_id: nil).order(:id)
    @lecons_en_vol = user_livrets.where.not(flight_lesson_id: nil).order(:id)

    render  pdf: "livret_progression_#{@selected_eleve.full_name.parameterize}",
            template: "progressions/show",
            layout: 'pdf_progression',
            page_size: 'A4',
            orientation: 'Portrait',
            lowquality: true,
            zoom: 1,
            dpi: 75,
            header: { html: { partial: 'layouts/pdf_progression_header' } },
            footer: { html: { partial: 'layouts/pdf_progression_footer' } }
  end


  private

  def authorize_access
    # Seuls les élèves et les instructeurs peuvent accéder à cette page.
    redirect_to root_path, alert: "Vous n'avez pas l'autorisation d'accéder à cette page." unless current_user.eleve? || current_user.instructeur? || current_user.admin?
  end
  
end
