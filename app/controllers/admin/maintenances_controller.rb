module Admin
  class MaintenancesController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin
    around_action :set_time_zone

    def index
      @avions = Avion.all.order(:immatriculation)
      @selected_avion = params[:avion_id].present? ? Avion.find_by(id: params[:avion_id]) : @avions.first
      
      if @selected_avion
        # Récupération des paramètres depuis la table settings (Clé = maintenance_avion_ID)
        # Valeur par défaut "110" : 50h=Oui, Annuelle=Oui, Parachute=Non
        setting_key = "maintenance_avion_#{@selected_avion.id}"
        setting_val = Setting.find_by(var: setting_key)&.val || "110"
        @check_50h = setting_val[0] == '1'
        @check_annuelle = setting_val[1] == '1'
        @check_parachute = setting_val[2] == '1'
        @check_1000h = setting_val[3] == '1'
      end
      
      # --- Données pour les graphiques ---
      
      # 2. Évolution de l'activité / Consommation de potentiel (Line Chart)
      # On calcule manuellement pour éviter la dépendance à la gem 'groupdate' si elle n'est pas là
      start_date = 11.months.ago.beginning_of_month
      end_date = Time.current.end_of_month
      vols_period = Vol.where(debut_vol: start_date..end_date)
      vols_period = vols_period.where(avion_id: @selected_avion.id) if @selected_avion
      
      @flight_hours_chart_data = (0..11).map do |i|
        date = start_date + i.months
        month_label = I18n.l(date, format: "%b %Y").capitalize
        total_hours = vols_period.select { |v| v.debut_vol.year == date.year && v.debut_vol.month == date.month }
                                  .sum(&:duree_vol).round(2)
        [month_label, total_hours]
      end

      # 3. Prévision d'épuisement du potentiel (Forecast)
      avions_scope = @selected_avion ? [@selected_avion] : @avions
      @forecast_chart_data = avions_scope.map do |avion|
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

      scope = ActivityLog.where(action: ['reset_100h', 'reset_50h', 'reset_1000h', 'reset_moteur', 'update_maintenance', 'reset_annuelle', 'reset_cen', 'notify_grounded'])
      
      if @selected_avion
        scope = scope.where(record_id: @selected_avion.id)
      end

      @total_logs = scope.count
      @total_pages = (@total_logs.to_f / @per_page).ceil
      @logs = scope.order(created_at: :desc).offset((@page - 1) * @per_page).limit(@per_page)
    end

    def show
      @avion = Avion.find(params[:id])
      @logs = ActivityLog.where(record_id: @avion.id, action: ['reset_100h', 'reset_50h', 'reset_1000h', 'reset_moteur', 'update_maintenance', 'reset_annuelle', 'reset_cen', 'notify_grounded']).order(created_at: :desc).limit(50)
      respond_to do |format|
        format.html { redirect_to admin_maintenances_path(avion_id: @avion.id) }
        format.pdf do
          render  pdf: "dossier_maintenance_#{@avion.immatriculation}",
                  template: "admin/maintenances/show",
                  layout: "pdf",
                  header: { html: { template: 'layouts/_pdf_maintenance_header', layout: false, formats: [:html] }, spacing: 10 },
                  footer: { html: { template: 'layouts/_pdf_footer', layout: false, formats: [:html] } },
                  disposition: "inline",
                  encoding: "UTF-8"
        end
      end
    end

    def update
      @avion = Avion.find(params[:id])
      
      # 1. On applique les nouveaux paramètres à l'objet en mémoire (sans sauvegarder tout de suite)
      @avion.assign_attributes(maintenance_params)
      
      # 2. On capture les changements détectés par Rails
      changes = @avion.changes.slice('marque', 'modele', 'moteur', 'potentiel_moteur', 'potentiel_cellule', 'next_100h', 'next_50h', 'next_1000h', 'annuelle', '_1000h', 'gv', 'tbo_helice', 'tbo_parachute', 'cert_examen_navigabilite')
      
      # 3. On tente de sauvegarder
      if @avion.save
        if changes.any?
          # 4. On construit le message d'historique basé sur les changements capturés
          details_parts = []
          changes.each do |attr, values|
            new_val = values[1] # La nouvelle valeur
            formatted_val = new_val.respond_to?(:strftime) ? new_val.strftime('%d/%m/%Y') : new_val.to_s
            
            attr_name = case attr
                        when 'marque' then 'Marque'
                        when 'modele' then 'Modèle'
                        when 'moteur' then 'Moteur'
                        when 'potentiel_moteur' then 'Potentiel Moteur'
                        when 'potentiel_cellule' then 'Potentiel Cellule'
                        when 'next_100h' then '100h'
                        when 'next_50h' then '50h'
                        when 'next_1000h' then '1000h'
                        when 'annuelle' then 'Annuelle'
                        when '_50h' then 'Date 50h'
                        when '_100h' then 'Date 100h'
                        when '_1000h' then 'Date 1000h'
                        when 'gv' then 'Grande Visite'
                        when 'tbo_helice' then 'TBO Hélice'
                        when 'tbo_parachute' then 'TBO Parachute'
                        when 'cert_examen_navigabilite' then 'CEN'
                        else attr
                        end
            
            details_parts << "#{attr_name} : #{formatted_val}"
          end

          details = "Mise à jour manuelle : #{details_parts.join(', ')}"
          log_maintenance_action("update_maintenance", details)
          redirect_to admin_maintenances_path(avion_id: @avion.id), notice: "Potentiels mis à jour pour #{@avion.immatriculation}."
        else
          redirect_to admin_maintenances_path(avion_id: @avion.id), notice: "Aucune modification détectée pour #{@avion.immatriculation}."
        end
      else
        redirect_to admin_maintenances_path(avion_id: @avion.id), alert: "Erreur lors de la mise à jour : #{@avion.errors.full_messages.join(', ')}"
      end
    end

    # reset du potentiel 50h
    def reset_50h
      @avion = Avion.find(params[:id])
      @avion.update(next_50h: 50.0)
      log_maintenance_action("reset_50h", "Réinitialisation visite 50h")
      redirect_to admin_maintenances_path(avion_id: @avion.id), notice: "Potentiel 50h réinitialisé pour #{@avion.immatriculation}."
    end

    # reset du potentiel moteur 100h
    def reset_100h
      @avion = Avion.find(params[:id])
      @avion.reset_potential_100h!
      log_maintenance_action("reset_100h", "Réinitialisation visite 100h")
      redirect_to admin_maintenances_path(avion_id: @avion.id), notice: "Potentiel 100h réinitialisé pour #{@avion.immatriculation}."
    end
    
    # reset du potentiel 1000h
    def reset_1000h
      @avion = Avion.find(params[:id])
      @avion.reset_potential_1000h!
      log_maintenance_action("reset_1000h", "Réinitialisation visite 1000h")
      redirect_to admin_maintenances_path(avion_id: @avion.id), notice: "Potentiel 1000h réinitialisé pour #{@avion.immatriculation}."
    end

    # reset du potentiel moteur (2000 heures)
    def reset_moteur
      @avion = Avion.find(params[:id])
      @avion.reset_potential_engine!
      log_maintenance_action("reset_moteur", "Réinitialisation potentiel moteur")
      redirect_to admin_maintenances_path(avion_id: @avion.id), notice: "Potentiel moteur réinitialisé pour #{@avion.immatriculation}."
    end

    # Validation de la visite annuelle
    def reset_annuelle
      @avion = Avion.find(params[:id])
      @avion.reset_potential_annuelle!
      log_maintenance_action("reset_annuelle", "Validation visite annuelle (nouvelle date : #{@avion.annuelle.strftime('%d/%m/%Y')})")
      redirect_to admin_maintenances_path(avion_id: @avion.id), notice: "Visite annuelle validée pour #{@avion.immatriculation}."
    end

    # Validation du CEN
    def reset_cen
      @avion = Avion.find(params[:id])
      @avion.reset_potential_cen!
      log_maintenance_action("reset_cen", "Validation CEN (nouvelle date : #{@avion.cert_examen_navigabilite.strftime('%d/%m/%Y')})")
      redirect_to admin_maintenances_path(avion_id: @avion.id), notice: "CEN validé pour #{@avion.immatriculation}."
    end

    def update_settings
      @avion = Avion.find(params[:id])
      
      # Encodage des booléens en chaîne de 3 chiffres (ex: "101")
      val_50h = params[:check_50h] == "1" ? "1" : "0"
      val_annuelle = params[:check_annuelle] == "1" ? "1" : "0"
      val_parachute = params[:check_parachute] == "1" ? "1" : "0"
      val_1000h = params[:check_1000h] == "1" ? "1" : "0"
      
      new_val = "#{val_50h}#{val_annuelle}#{val_parachute}#{val_1000h}"
      
      setting_key = "maintenance_avion_#{@avion.id}"
      setting = Setting.find_or_initialize_by(var: setting_key)
      setting.val = new_val
      setting.save
      
      redirect_to admin_maintenances_path(avion_id: @avion.id), notice: "Paramètres de maintenance mis à jour."
    end

    # Déclenche manuellement les notifications d'annulation pour les avions indisponibles
    def notify_grounded
      count = 0
      
      Avion.all.each do |avion|
        next unless avion.grounded?

        unavailability_end_date = nil

        # Règle : 1 semaine pour une visite 1000 heures / Potentiel moteur épuisé
        if avion.potentiel_moteur <= 0
          date_potential = 1.week.from_now.to_date
          unavailability_end_date = unavailability_end_date ? [unavailability_end_date, date_potential].max : date_potential
        end

        # Règle : 1 journée (le jour de l'immobilisation) pour une visite 100 heures
        if avion.next_100h.present? && avion.next_100h <= 0
          date_100h = Date.today
          unavailability_end_date = unavailability_end_date ? [unavailability_end_date, date_100h].max : date_100h
        end

        if unavailability_end_date
          # On récupère les réservations futures qui tombent dans la période d'indisponibilité
          reservations_to_cancel = avion.reservations.where(
            "start_time >= ? AND start_time <= ?", 
            Time.current, 
            unavailability_end_date.end_of_day
          ).where.not(status: 'cancelled')

          reservations_to_cancel.each do |reservation|
            reservation.update(status: 'cancelled')
            # UserMailer.maintenance_cancellation_email(reservation.user, reservation, unavailability_end_date).deliver_later if defined?(UserMailer)
            count += 1
          end

          if reservations_to_cancel.any?
            ActivityLog.create(
              user: current_user,
              action: 'notify_grounded',
              record_type: avion.immatriculation,
              record_id: avion.id,
              details: "Annulation automatique de #{reservations_to_cancel.count} réservation(s) jusqu'au #{unavailability_end_date.strftime('%d/%m/%Y')}"
            )
          end
        end
      end
      redirect_to admin_maintenances_path, notice: "#{count} réservations ont été annulées et les pilotes notifiés selon les durées de maintenance prévues."
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
      params.require(:avion).permit(:marque, :modele, :moteur, :potentiel_moteur, :potentiel_cellule, :next_100h, :next_50h, :next_1000h, :annuelle, :_1000h, :gv, :tbo_helice, :tbo_parachute, :cert_examen_navigabilite, :cen_document, :check_50h, :check_annuelle, :check_parachute)
    end

    def log_maintenance_action(action_name, details)
      ActivityLog.create(
        user: current_user,
        action: action_name,
        record_type: @avion.immatriculation,
        record_id: @avion.id,
        details: details
      )
    end
  end
  
end
