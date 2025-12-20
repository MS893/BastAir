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
    l_params = livret_params

    # Gestion de la signature : on détermine si c'est celle de l'instructeur ou de l'élève
    if l_params[:signature_data].present?
      if (current_user.instructeur? || current_user.admin?) && current_user != @livret.user
        @livret.instructor_signature_data = l_params[:signature_data]
      else
        @livret.signature_data = l_params[:signature_data]
      end
    end

    # On assigne les autres attributs (status, date, etc.)
    @livret.assign_attributes(l_params.except(:signature_data, :instructor_signature_data))

    # Sécurité : L'élève ne peut pas signer si l'instructeur n'a pas encore signé (uniquement pour les leçons de vol)
    if @livret.signature_data.present? && current_user == @livret.user && !@livret.instructor_signature.attached? && @livret.flight_lesson_id.present?
      redirect_to signature_livret_path(@livret), alert: "Vous ne pouvez pas signer cette leçon tant que l'instructeur ne l'a pas signée."
      return
    end

    # Auto-validation des FTP (cours théoriques) lors de la signature de l'élève
    if @livret.course_id.present? && (@livret.signature_data.present? || l_params[:signature_data].present?)
      @livret.status = 3
    end

    respond_to do |format|
      if @livret.save
        format.html do
          if @livret.flight_lesson_id.present? || request.referer&.include?('livret_progression')
            redirect_to livret_progression_path(eleve_id: @livret.user_id), notice: 'Livret mis à jour avec succès.'
          else
            redirect_to elearning_index_path, notice: 'Cours validé et signé avec succès !'
          end
        end
      else
        format.html { redirect_to signature_livret_path(@livret), alert: "Erreur lors de la signature : #{@livret.errors.full_messages.join(', ')}" }
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
