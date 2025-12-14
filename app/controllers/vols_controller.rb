class VolsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pilots, only: [:index] # S'exécute en premier pour initialiser @pilots
  before_action :set_avions, only: [:index] # Doit s'exécuter avant set_page_title_and_vols
  before_action :set_page_title_and_vols, only: [:index]
  before_action :combine_date_and_time, only: [:create]
  
  def index
    respond_to do |format|
      format.html
      # Pour l'export CSV, on s'assure que @vols contient tous les vols filtrés, sans pagination.
      format.csv { send_data Vol.to_csv(@vols), filename: "export-vols-#{Date.today}.csv" }
    end
  end

  def new
    @vol = Vol.new
    # On charge les avions et instructeurs pour les menus déroulants du formulaire
    @avions = Avion.order(:immatriculation)
    @instructeurs = User.where(fonction: 'instructeur').order(:prenom, :nom)
    # On charge la liste des comptes BIA pour la modale de sélection
    @bia_users = User.where("LOWER(prenom) = ?", 'bia').order(:nom)
    # Assurez-vous d'avoir au moins un tarif dans votre base de données
    @tarif = Tarif.order(annee: :desc).first
  end

  def create
    @vol = current_user.vols.build(vol_params)

    if @vol.save
      redirect_to root_path, notice: 'Votre vol a été enregistré avec succès.'
    else
      # Si la sauvegarde échoue, nous devons recharger les variables pour le formulaire
      @avions = Avion.order(:immatriculation)
      @instructeurs = User.where(fonction: 'instructeur').order(:prenom, :nom)
      @bia_users = User.where("LOWER(prenom) = ?", 'bia').order(:nom)
      @tarif = Tarif.order(annee: :desc).first
      render :new, status: :unprocessable_entity
    end
  end
  
  
  private

  def vol_params
    params.require(:vol).permit(:avion_id, :type_vol, :depart, :arrivee, :nb_atterro, :debut_vol, :fin_vol, :compteur_depart, :compteur_arrivee, :duree_vol, :fuel_avant_vol, :fuel_apres_vol, :huile, :nature, :instructeur_id, :solo, :supervise, :nav, :debut_vol_date, :debut_vol_hour, :debut_vol_minute, :bia_user_id)
  end

  def combine_date_and_time
    # Combine la date et l'heure pour le début du vol
    if params[:vol][:debut_vol_date].present? && params[:vol][:debut_vol_hour].present? && params[:vol][:debut_vol_minute].present?
      date = Date.parse(params[:vol][:debut_vol_date])
      hour = params[:vol][:debut_vol_hour].to_i
      minute = params[:vol][:debut_vol_minute].to_i
      
      # On reconstruit le paramètre debut_vol avec la date et l'heure
      # avant qu'il ne soit utilisé par vol_params
      params[:vol][:debut_vol] = Time.zone.local(date.year, date.month, date.day, hour, minute)
    end
    # La fin du vol est calculée automatiquement, donc pas besoin de la combiner ici.
  end

  def set_page_title_and_vols
    base_scope = Vol.includes(:user, :avion).order(debut_vol: :desc)

    case params[:period]
    when 'day'
      @page_title = "Vols d'aujourd'hui"
      @vols = base_scope.where(debut_vol: Time.zone.now.all_day)
    when 'week'
      @page_title = "Vols de cette semaine"
      @vols = base_scope.where(debut_vol: Time.zone.now.all_week)
    when 'month'
      @page_title = "Vols de ce mois-ci"
      @vols = base_scope.where(debut_vol: Time.zone.now.all_month)
    when 'year'
      @page_title = "Vols de cette année"
      @vols = base_scope.where(debut_vol: Time.zone.now.all_year)
    else
      @page_title = "Tous les vols"
      @vols = base_scope
    end

    # Ajout du filtre par pilote si un pilot_id est fourni
    if params[:pilot_id].present?
      @vols = @vols.where(user_id: params[:pilot_id])
      # On cherche le pilote dans la liste déjà chargée pour éviter une requête N+1
      pilot = @pilots.find { |p| p.id == params[:pilot_id].to_i }
      if pilot
        @page_title += " de #{pilot.name}"
      end
    end

    # Ajout du filtre par avion si un avion_id est fourni
    if params[:avion_id].present?
      @vols = @vols.where(avion_id: params[:avion_id])
      # On cherche l'avion dans la liste déjà chargée pour éviter une requête N+1
      avion = @avions.find { |a| a.id == params[:avion_id].to_i }
      if avion
        @page_title += " sur #{avion.immatriculation}"
      end
    end

    # On calcule les totaux sur la collection filtrée AVANT la pagination
    # Utiliser .count(:all) est plus robuste pour éviter les effets de bord des 'includes'.
    @total_flights_count = @vols.count(:all)
    @total_duration = @vols.sum(:duree_vol)

    # On ne pagine que pour le format HTML. Pour le CSV, @vols garde tous les résultats.
    @vols = @vols.page(params[:page]).per(25) unless request.format.csv?
  end

  def set_pilots
    # En exécutant cette méthode en dernier, on s'assure qu'elle n'est affectée
    # par aucune autre requête. `unscoped` est la protection la plus simple et efficace ici.
    pilot_ids = Vol.unscoped.distinct.pluck(:user_id)
    @pilots = User.where(id: pilot_ids).order(:prenom, :nom)
  end

  def set_avions
    # On récupère tous les avions qui ont au moins un vol
    avion_ids = Vol.unscoped.distinct.pluck(:avion_id)
    @avions = Avion.where(id: avion_ids).order(:immatriculation)
  end

end
