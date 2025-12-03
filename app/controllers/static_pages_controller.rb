class StaticPagesController < ApplicationController
  
  def home
    # Affiche un message si le paiement a été annulé
    if params[:canceled]
      flash.now[:alert] = "Le paiement a été annulé. Vous n'êtes pas inscrit à l'événement."
    end

    # Gestion de la redirection après un paiement Stripe réussi pour un événement
    if params[:success] && params[:session_id]
      begin
        session = Stripe::Checkout::Session.retrieve(params[:session_id])
        # On s'assure que la session est bien pour un événement
        if session.metadata.event_id
          event = Event.find(session.metadata.event_id)
          # On vérifie que l'utilisateur n'est pas déjà inscrit pour éviter les doublons
          unless event.users.include?(current_user)
            current_user.update(stripe_customer_id: session.customer) if current_user.stripe_customer_id.nil?
            Attendance.create(user: current_user, event: event, stripe_customer_id: session.customer)
            flash.now[:notice] = "Félicitations ! Vous êtes bien inscrit à l'événement #{event.title}."
          end
        end
      rescue Stripe::InvalidRequestError => e
        logger.error "Stripe Error: #{e.message}"
      end
    end

    # On récupère les 5 dernières transactions de l'utilisateur connecté pour le dashboard
    if user_signed_in?
      @transactions = current_user.transactions.order(date_transaction: :desc).limit(4)
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
    # Logique pour récupérer les disponibilités des instructeurs à venir
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
    file_path = Rails.root.join('app', 'assets', 'files', 'download', filename)

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
      render :baptemes, status: :unprocessable_entity
    else
      # Envoyer l'email
      ContactMailer.contact_email(@nom, @prenom, @email, @message).deliver_now
      redirect_to baptemes_path, notice: "Votre message a bien été envoyé. Nous vous répondrons dans les plus brefs délais."
    end
  end
end
