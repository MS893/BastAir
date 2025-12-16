class LivretsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_livret, only: [:update, :signature]

  def create
    # Not implemented yet
  end

  def update
    @livret = Livret.find(params[:id])
    
    # On met à jour le livret avec les paramètres autorisés
    respond_to do |format|
      if @livret.update(livret_params)
        format.html do
          if request.referer&.include?('livret_progression')
            redirect_to livret_progression_path(eleve_id: @livret.user_id), notice: 'Livret mis à jour avec succès.'
          else
            redirect_to elearning_index_path, notice: 'Cours validé et signé avec succès !'
          end
        end
        # Pour les requêtes Turbo, on recharge les données et on rend la vue partielle
        format.turbo_stream do
          @selected_eleve = @livret.user
          @examens_theoriques = @selected_eleve.livrets.where(course_id: nil, flight_lesson_id: nil).order(:id)
          render 'progressions/examens_theoriques_list'
        end
      end
    end
  end

  def signature
    # @livret est défini par le before_action
    # Vérification des autorisations : seul le propriétaire, un admin ou un instructeur peut voir la signature.
    unless @livret.user == current_user || current_user.admin? || current_user.fi?
      redirect_to elearning_index_path, alert: "Vous n'êtes pas autorisé à voir cette signature."
      return
    end
    # La vue `app/views/livrets/signature.html.erb` sera rendue implicitement.
  end

  
  private

  def set_livret
    @livret = Livret.find(params[:id])
  end

  def livret_params
    params.require(:livret).permit(:signature_data, :status, :date)
  end

end
