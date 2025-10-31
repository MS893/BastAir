class ElearningController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_eleve!
  before_action :set_course, only: [:show, :document]

  def show
    # La variable @course est maintenant définie par le before_action :set_course
    # La vue show.html.erb est rendue implicitement.
  end

  def document
    if @course.document.attached?
      # Redirige vers l'URL du document pour que le navigateur l'affiche (inline).
      redirect_to @course.document.url(disposition: :inline), allow_other_host: true
    else
      # Si aucun document n'est attaché, on redirige avec une alerte.
      redirect_to elearning_index_path, alert: "Le document pour ce cours est introuvable."
    end
  end

  def index
    @courses = Course.order(:id)
    @audios = Audio.order(:title)
  end

  
  private

  def set_course
    @course = Course.find(params[:id])
  end

end
