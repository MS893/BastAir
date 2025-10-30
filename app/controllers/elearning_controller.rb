class ElearningController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_eleve!, only: [:index, :show, :document]


  def show
    # Cette action va maintenant rendre la vue show.html.erb
    # Active Storage gère l'existence du fichier, plus besoin de vérification manuelle ici.
    @course = Course.find(params[:id])
  end

  def document
    course = Course.find(params[:id])
    # On vérifie que le document est bien attaché
    if course.document.attached?
      # On redirige vers l'URL du fichier gérée par Active Storage.
      # `disposition: 'inline'` indique au navigateur d'essayer d'afficher le fichier.
      redirect_to course.document.url(disposition: 'inline')
    else
      # Si aucun document n'est attaché, on renvoie une erreur 404.
      head :not_found
    end
  end

  def index
    @courses = Course.order(:id)
    @audios = Audio.order(:title)
  end

end
