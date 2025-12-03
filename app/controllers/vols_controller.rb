class VolsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pilots, only: [:index] # S'exécute en premier pour initialiser @pilots
  before_action :set_avions, only: [:index] # Doit s'exécuter avant set_page_title_and_vols
  before_action :set_page_title_and_vols, only: [:index]
  
  def index
    respond_to do |format|
      format.html
      # Pour l'export CSV, on s'assure que @vols contient tous les vols filtrés, sans pagination.
      format.csv { send_data Vol.to_csv(@vols), filename: "export-vols-#{Date.today}.csv" }
    end
  end

  private

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
