module Admin
  class MaintenancesController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin
    around_action :set_time_zone

    def index
      @avions = Avion.all.order(:immatriculation)
      
      # --- Données pour les graphiques ---
      
      # 2. Évolution de l'activité / Consommation de potentiel (Line Chart)
      # On calcule manuellement pour éviter la dépendance à la gem 'groupdate' si elle n'est pas là
      start_date = 11.months.ago.beginning_of_month
      end_date = Time.current.end_of_month
      vols_period = Vol.where(debut_vol: start_date..end_date)
      
      @flight_hours_chart_data = (0..11).map do |i|
        date = start_date + i.months
        month_label = I18n.l(date, format: "%b %Y").capitalize
        total_hours = vols_period.select { |v| v.debut_vol.year == date.year && v.debut_vol.month == date.month }
                                 .sum(&:duree_vol).round(2)
        [month_label, total_hours]
      end

      # 3. Prévision d'épuisement du potentiel (Forecast)
      @forecast_chart_data = @avions.map do |avion|
        # Consommation sur les 12 derniers mois
        consumption_last_year = Vol.where(avion: avion, debut_vol: 1.year.ago..Time.current).sum(:duree_vol).to_f
        avg_daily_consumption = consumption_last_year / 365.0
        
        data_points = {}
        # Point de départ : aujourd'hui
        data_points[Time.zone.today] = avion.potentiel_moteur
        
        if avg_daily_consumption > 0
          days_remaining = avion.potentiel_moteur / avg_daily_consumption
          
          # On limite la projection à 2 ans (730 jours) pour la lisibilité
          limit_days = 730
          
          if days_remaining > limit_days
            target_date = Time.zone.today + limit_days.days
            remaining_potential_at_limit = avion.potentiel_moteur - (avg_daily_consumption * limit_days)
            data_points[target_date] = remaining_potential_at_limit.round(2)
          else
            target_date = Time.zone.today + days_remaining.days
            data_points[target_date] = 0
          end
        else
          # Si pas de consommation, ligne plate sur 1 an
          data_points[Time.zone.today + 1.year] = avion.potentiel_moteur
        end
        
        { name: avion.immatriculation, data: data_points }
      end

      # Pagination
      @page = (params[:page] || 1).to_i
      @per_page = 20

      scope = ActivityLog.where(record_type: 'Avion', action: ['reset_100h', 'reset_moteur', 'update_maintenance', 'reset_annuelle', 'reset_cen', 'notify_grounded'])
      
      if params[:avion_id].present?
        scope = scope.where(record_id: params[:avion_id])
      end

      @total_logs = scope.count
      @total_pages = (@total_logs.to_f / @per_page).ceil
      @logs = scope.order(created_at: :desc).offset((@page - 1) * @per_page).limit(@per_page)
    end

    def update
      @avion = Avion.find(params[:id])
      if @avion.update(maintenance_params)
        log_maintenance_action("update_maintenance", "Mise à jour manuelle : Moteur #{@avion.potentiel_moteur}h, 100h #{@avion.next_100h}h, Annuelle #{@avion.annuelle}, CEN #{@avion.cert_examen_navigabilite}")
        redirect_to admin_maintenances_path, notice: "Potentiels mis à jour pour #{@avion.immatriculation}."
      else
        redirect_to admin_maintenances_path, alert: "Erreur lors de la mise à jour."
      end
    end

    # reset du potentiel moteur 100h
    def reset_100h
      @avion = Avion.find(params[:id])
      @avion.reset_potential_100h!
      log_maintenance_action("reset_100h", "Réinitialisation visite 100h")
      redirect_to admin_maintenances_path, notice: "Potentiel 100h réinitialisé pour #{@avion.immatriculation}."
    end
    
    # reset du potentiel moteur 2000 heures
    def reset_moteur
      @avion = Avion.find(params[:id])
      @avion.reset_potential_engine!
      log_maintenance_action("reset_moteur", "Réinitialisation potentiel moteur")
      redirect_to admin_maintenances_path, notice: "Potentiel moteur réinitialisé pour #{@avion.immatriculation}."
    end

    # Validation de la visite annuelle
    def reset_annuelle
      @avion = Avion.find(params[:id])
      @avion.reset_potential_annuelle!
      log_maintenance_action("reset_annuelle", "Validation visite annuelle (nouvelle date : #{@avion.annuelle.strftime('%d/%m/%Y')})")
      redirect_to admin_maintenances_path, notice: "Visite annuelle validée pour #{@avion.immatriculation}."
    end

    # Validation du CEN
    def reset_cen
      @avion = Avion.find(params[:id])
      @avion.reset_potential_cen!
      log_maintenance_action("reset_cen", "Validation CEN (nouvelle date : #{@avion.cert_examen_navigabilite.strftime('%d/%m/%Y')})")
      redirect_to admin_maintenances_path, notice: "CEN validé pour #{@avion.immatriculation}."
    end

    # Déclenche manuellement les notifications d'annulation pour les avions indisponibles
    def notify_grounded
      count = 0
      Avion.all.each do |avion|
        if avion.grounded?
          avion.notify_future_reservations
          ActivityLog.create(
            user: current_user,
            action: 'notify_grounded',
            record_type: 'Avion',
            record_id: avion.id,
            details: "Envoi manuel des notifications d'annulation aux pilotes"
          )
          count += 1
        end
      end
      redirect_to admin_maintenances_path, notice: "Vérification effectuée sur #{count} avion(s) indisponible(s). Les notifications d'annulation ont été envoyées aux pilotes concernés."
    end



    private

    def ensure_admin
      redirect_to root_path, alert: "Accès refusé." unless current_user&.admin?
    end

    def set_time_zone(&block)
      # On récupère le fuseau horaire dans les paramètres, ou Paris par défaut
      timezone = Setting.find_by(var: 'time_zone')&.val || 'Europe/Paris'
      Time.use_zone(timezone, &block)
    end

    def maintenance_params
      params.require(:avion).permit(:potentiel_moteur, :next_100h, :annuelle, :cert_examen_navigabilite, :cen_document)
    end

    def log_maintenance_action(action_name, details)
      ActivityLog.create(
        user: current_user,
        action: action_name,
        record_type: 'Avion',
        record_id: @avion.id,
        details: details
      )
    end
  end
  
end
