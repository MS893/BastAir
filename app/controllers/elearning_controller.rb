class ElearningController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_eleve!, only: [:index, :show, :document]


  def show
    # Cette action va maintenant rendre la vue show.html.erb
    @course = Course.find(params[:id])

    # On vérifie si le fichier PDF associé existe avant de rendre la vue.
    pdf_name = "#{@course.title.parameterize(separator: '_')}.pdf"
    pdf_path = Rails.root.join('app', 'assets', 'files', pdf_name)

    unless File.exist?(pdf_path)
      redirect_to cours_theoriques_path, alert: "Le document pour le cours '#{@course.title}' est introuvable."
      return # Important pour stopper l'exécution et éviter une double-render error
    end
    # Si le fichier existe, la vue show.html.erb est rendue normalement.
  end

  def document
    course = Course.find(params[:id])
    pdf_name = "#{course.title.parameterize(separator: '_')}.pdf"
    pdf_path = Rails.root.join('app', 'assets', 'files', pdf_name)

    if File.exist?(pdf_path)
      send_file(pdf_path,
                filename: pdf_name,
                type: "application/pdf",
                disposition: 'inline')
    else
      # Si le fichier n'existe pas, on renvoie une erreur 404
      head :not_found
    end
  end

  def index
    @courses = Course.order(:id)
    @audios = Audio.order(:title)
  end

end
