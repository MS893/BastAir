class StaticPagesController < ApplicationController
  
  def home
    # Affiche un message si le paiement a été annulé
    if params[:canceled]
      flash.now[:alert] = "Le paiement a été annulé."
    end

    # Gestion de la redirection après un paiement Stripe réussi
    if params[:success]
      flash.now[:notice] = "Paiement réussi ! Votre compte a été crédité. Le solde peut prendre quelques instants pour se mettre à jour."
    end

    # On récupère les 5 dernières transactions de l'utilisateur connecté pour le dashboard
    if user_signed_in?
      # On vérifie si le contact d'urgence est invalide pour afficher une alerte
      # On ne lance la validation que si le champ n'est pas vide.
      if current_user.contact_urgence.present? && !current_user.valid?(:update_profil)
        flash.now[:warning] = "Votre numéro de contact d'urgence semble invalide. #{view_context.link_to('Veuillez le corriger ici', edit_profil_user_path(current_user))}".html_safe
      end

      # On vérifie les validités qui expirent bientôt
      validity_warnings = current_user.validity_warnings
      if validity_warnings.any?
        # On combine les avertissements en un seul message flash.
        flash.now[:info] = validity_warnings.join('<br>').html_safe
      end

      @transactions = current_user.transactions.order(date_transaction: :desc).limit(5)

      # On charge les 3 prochaines réservations de l'utilisateur
      @upcoming_reservations = current_user.reservations.where('start_time >= ?', Time.current).order(start_time: :asc).limit(3)
      @upcoming_reservations_count = current_user.reservations.where('start_time >= ?', Time.current).count
    end

    # On charge les 5 dernières actualités, de la plus récente à la plus ancienne
    @news_items = NewsItem.order(created_at: :desc).limit(5)
  end

  def flotte
    # cette action rendra la vue app/views/static_pages/flotte.html.erb
  end

  def mediatheque
    # cette action rendra la vue app/views/static_pages/mediatheque.html.erb
  end

  def tarifs
    # on récupère le tarif annuel le plus récent
    @tarif = Tarif.order(annee: :desc).first
  end

  def credit
    # possibilité de cérdit son compte adhérent
    tarif_horaire = Tarif.order(annee: :desc).first.tarif_horaire_avion1
    @prix_bloc_6h = 6 * (tarif_horaire - 5)
    @prix_bloc_10h = 10 * (tarif_horaire - 10)
  end

  def bia
    # cette action rendra la vue app/views/static_pages/bia.html.erb
  end

  def baptemes
    # cette action rendra la vue app/views/static_pages/baptemes.html.erb
  end

  def outils
    # cette action rendra la vue app/views/static_pages/outils.html.erb
  end

  def agenda_avion
    # Logique pour récupérer les réservations de l'avion à venir
    # @reservations_avion = Reservation.where('date_debut >= ?', Time.current).order(:date_debut)
  end

  def agenda_instructeurs
    # On récupère toutes les disponibilités et on les groupe par créneau (ex: "lundi-matin").
    # On inclut :user pour éviter les requêtes N+1 dans la vue.
    @availabilities_by_slot = InstructorAvailability.includes(:user).all.group_by do |availability|
      "#{availability.day}-#{availability.period}"
    end

    # On prépare les données pour la vue afin de gérer les clics des instructeurs
    if user_signed_in?
      @instructor_status = {
        is_instructor: current_user.instructeur?,
        fi_present: current_user.fi.present?,
        fi_expired: current_user.fi.present? && current_user.fi < Date.today
      }
    end
  end

  def documents_divers
    downloads_path = Rails.root.join('app', 'assets', 'files', 'download')
    @files = []

    if Dir.exist?(downloads_path)
      # On récupère uniquement les noms de fichiers, pas les chemins complets
      @files = Dir.children(downloads_path).sort
    else
      flash.now[:alert] = "Le dossier de téléchargement n'a pas été trouvé."
    end
  end

  def download
    filename = params[:filename]
    downloads_path = Rails.root.join('app', 'assets', 'files', 'download')

    # Sécurisation : On s'assure que le nom de fichier ne contient pas de ".."
    # et qu'il correspond bien à un nom de fichier simple.
    secure_filename = File.basename(filename)

    file_path = downloads_path.join(secure_filename)

    if File.exist?(file_path)
      # 'disposition: "attachment"' force le téléchargement
      send_file file_path, disposition: 'attachment'
    else
      redirect_to documents_divers_path, alert: "Le fichier demandé n'existe pas."
    end
  end

  def create_contact
    @nom = params[:nom]
    @prenom = params[:prenom]
    @email = params[:email]
    @message = params[:message]

    # Validation du format de l'email côté serveur
    if !verify_recaptcha || @email.blank? || !@email.match?(/\A[^@\s]+@[^@\s]+\z/)
      flash.now[:alert] = "La vérification reCAPTCHA a échoué ou l'email est invalide. Veuillez réessayer."
      render :baptemes, status: ::unprocessable_content
    else
      # Envoyer l'email
      ContactMailer.contact_email(@nom, @prenom, @email, @message).deliver_now
      redirect_to baptemes_path, notice: "Votre message a bien été envoyé. Nous vous répondrons dans les plus brefs délais."
    end
  end

end
