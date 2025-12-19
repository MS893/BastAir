# app/controllers/livrets_controller.rb

class LivretsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_livret, only: [:show, :update, :signature]

  def create
    # Not implemented yet
  end

  def show
    # Redirige vers la page de signature, qui agit comme la vue "show" pour un livret.
    redirect_to signature_livret_path(@livret)
  end

  def update
    # On met à jour le livret avec les paramètres autorisés
    l_params = livret_params

    # Si une signature est soumise et que l'utilisateur est un instructeur (et pas l'élève propriétaire),
    # on mappe la donnée vers la signature instructeur.
    if l_params[:signature_data].present? && (current_user.instructeur? || current_user.admin?) && current_user != @livret.user
      l_params[:instructor_signature_data] = l_params[:signature_data]
      l_params.delete(:signature_data)
    end

    respond_to do |format|
      if @livret.update(l_params)
        format.html do
          if request.referer&.include?('livret_progression')
            redirect_to livret_progression_path(eleve_id: @livret.user_id), notice: 'Livret mis à jour avec succès.'
          else
            redirect_to elearning_index_path, notice: 'Cours validé et signé avec succès !'
          end
        end
        # Pour les requêtes Turbo, on recharge les données et on rend la vue partial
        #format.turbo_stream do
        #  @selected_eleve = @livret.user
        #  @examens_theoriques = @selected_eleve.livrets.where(course_id: nil, flight_lesson_id: nil).order(:id)
        #  render 'progressions/examens_theoriques_list'
        #end
        format.turbo_stream do
          # On recharge l'instance @livret depuis la base de données
          @livret.reload
        end
      end
    end
  end

  def signature
    # @livret est défini par le before_action
    # Vérification des autorisations : seul le propriétaire, un admin ou un instructeur peut voir la signature.
    unless @livret.user == current_user || current_user.admin? || current_user.instructeur?
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
    params.require(:livret).permit(:signature_data, :instructor_signature_data, :status, :date)
  end

end
