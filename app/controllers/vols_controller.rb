class VolsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!, only: [:index] # Protège la nouvelle action

  def index
    @vols = Vol.includes(:user, :avion).all
    @period = params[:period]
  
    # --- Logique pour le titre dynamique ---
    @page_title = case @period
                  when 'day'
                    "Liste des vols d'aujourd'hui"
                  when 'week'
                    "Liste des vols de la semaine"
                  when 'month'
                    "Liste des vols du mois"
                  when 'year'
                    "Liste des vols de l'année"
                  else
                    "Liste de tous les vols"
                  end
  
    current_time = Time.zone.now
    case @period
    when 'day'
      @vols = @vols.where(debut_vol: current_time.all_day)
    when 'week'
      @vols = @vols.where(debut_vol: current_time.all_week)
    when 'month'
      @vols = @vols.where(debut_vol: current_time.all_month)
    when 'year'
      @vols = @vols.where(debut_vol: current_time.all_year)
    end
  
    # --- Calcul des totaux AVANT la pagination ---
    @total_flights_count = @vols.size
    @total_duration = @vols.sum(:duree_vol)
  
    # --- Pagination ---
    @vols = @vols.order(debut_vol: :desc).page(params[:page]).per(20)
  end

  def new
    @avions = Avion.all
    @vol = Vol.new(
      user: current_user,
      debut_vol: Time.current.beginning_of_minute,
      avion: @avions.first,   # Sélectionne le premier avion par défaut
      fuel_avant_vol: 0,      # Met le carburant à 0 par défaut
      fuel_apres_vol: 0,      # Met le carburant après vol à 0 par défaut
      huile: 0,               # Met l'huile'à 0 par défaut
      nature: 'VFR de jour',  # "VFR de jour" par défaut
      type_vol: 'Standard'    # Sélectionne "Standard" par défaut
    )
  end

  def create
    @vol = Vol.new(vol_params)
    @vol.user = current_user # Assure que le vol est bien lié à l'utilisateur connecté

    if @vol.save
      redirect_to root_path, notice: 'Votre vol a été enregistré avec succès.'
    else
      @avions = Avion.all # Il faut recharger @avions pour que le formulaire se ré-affiche correctement
      render :new, status: :unprocessable_entity
    end
  end

  
  private

  def vol_params
    params.require(:vol).permit(
      :avion_id, :type_vol, :depart, :arrivee, :debut_vol, :fin_vol,
      :compteur_depart, :compteur_arrivee, :duree_vol, :nb_atterro,
      :solo, :supervise, :nav, :nature, :fuel_avant_vol, :fuel_apres_vol, :huile
    )
  end
end