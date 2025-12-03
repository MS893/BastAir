class VolsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_page_title_and_vols, only: [:index]

  def index
    respond_to do |format|
      format.html
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

    # Pour les totaux affichés sur la page
    @total_flights_count = @vols.count
    @total_duration = @vols.sum(:duree_vol)

    @vols = @vols.page(params[:page]).per(25) unless request.format.csv?
  end
end