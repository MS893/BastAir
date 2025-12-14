class ElearningController < ApplicationController
  before_action :authenticate_user!, except: [:document] # Le document lui-même n'a pas besoin d'authentification
  before_action :authorize_student_area!, only: [:index, :show] # Seuls les élèves peuvent voir la liste et la page d'un cours
  before_action :set_course, only: [:show, :document]

  def show
    # La variable @course est maintenant définie par le before_action :set_course
    # La vue show.html.erb est rendue implicitement.
  end

  def document
    if @course.document.attached?
      # Envoie directement les données du fichier au navigateur
      # 'disposition: "inline"' demande au navigateur de l'afficher plutôt que de le télécharger
      send_data @course.document.download, filename: @course.document.filename.to_s, type: @course.document.content_type, disposition: 'inline'
    else
      # Si aucun document n'est attaché, on redirige.
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
