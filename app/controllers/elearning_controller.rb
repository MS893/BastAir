class ElearningController < ApplicationController
  before_action :authenticate_user!, except: [:document] # Le document lui-même n'a pas besoin d'authentification
  before_action :authorize_student_area!, only: [:index, :show] # Seuls les élèves peuvent voir la liste et la page d'un cours
  before_action :set_course, only: [:show, :document]

  def show
    # La variable @course est maintenant définie par le before_action :set_course

    # On cherche un livret existant pour l'utilisateur connecté ET le cours actuel
    # S'il n'en existe pas, on le crée pour permettre l'accès à la page de signature (qui nécessite un ID)
    @livret = Livret.find_or_create_by(user: current_user, course: @course)

    # On vérifie si le cours a déjà été validé et signé pour l'afficher dans la vue
    @quiz_validated = @livret.persisted? && @livret.status == 3 && @livret.signature_image.attached?
    
    # --- Logique pour charger le contenu Markdown ---
    @markdown_content = nil
    # On déduit le nom du fichier depuis le titre du cours (ex: "FTP1 ...")
    # Sécurisation : On s'assure que l'identifiant ne peut pas être utilisé pour une traversée de répertoire
    course_identifier = @course.title.split.first.to_s.downcase

    # Liste blanche des identifiants de cours autorisés pour la sécurité
    allowed_identifiers = %w[ftp1 ftp2 ftp3 ftp4 ftp5 ftp6 ftp7 ftp8 ftp9 ftp10 ftp11 ftp12]
    return unless allowed_identifiers.include?(course_identifier)

    markdown_file_path = Rails.root.join('lib', 'assets', 'ftp', "#{course_identifier}.md")
    
    if File.exist?(markdown_file_path)
      file_content = File.read(markdown_file_path)
      @markdown_content = MarkdownService.new.render(file_content)
    end
    # La vue show.html.erb est rendue implicitement
  end

  def document
    if @course.document.attached?
      # envoie directement les données du fichier au navigateur
      # 'disposition: "inline"' demande au navigateur de l'afficher plutôt que de le télécharger
      send_data @course.document.download, filename: @course.document.filename.to_s, type: @course.document.content_type, disposition: 'inline'
    else
      # si aucun document n'est attaché, on redirige
      redirect_to elearning_index_path, alert: "Le document pour ce cours est introuvable."
    end
  end

  def index
    @courses = Course.order(:id)
    @audios = Audio.order(:title)
    # On précharge le livret de l'élève pour optimiser les requêtes dans la vue
    @user_livrets = Livret.where(user: current_user, course_id: @courses.pluck(:id)).index_by(&:course_id)
  end

  
  
  private

  def set_course
    @course = Course.find(params[:id])
  end

end
