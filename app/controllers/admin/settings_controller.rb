# frozen_string_literal: true

module Admin
  class SettingsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_admin!

    def edit
      # On charge la liste des fuseaux horaires disponibles.
      @available_time_zones = Setting::ALLOWED_TIME_ZONES

      # On récupère le paramètre actuel ou on utilise la valeur par défaut.
      @time_zone = Setting.find_or_create_by(var: 'time_zone') do |setting|
        setting.val = 'Europe/Paris'
      end
    end

    def update
      @time_zone = Setting.find_or_create_by(var: 'time_zone')
      if @time_zone.update(val: params[:setting][:val])
        redirect_to edit_admin_setting_path, notice: 'Le fuseau horaire a été mis à jour avec succès.'
      else
        render :edit, status: :unprocessable_content
      end
    end
  end
end
