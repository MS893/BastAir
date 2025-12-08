# app/controllers/admin/google_calendars_controller.rb

module Admin
  class GoogleCalendarsController < ApplicationController
    before_action :authorize_admin!

    # Affiche la page de gestion avec la liste des calendriers
    def index
      @calendars = GoogleCalendarService.new.list_calendars
    rescue => e
      # Gère les erreurs de connexion à l'API Google
      @calendars = []
      flash.now[:alert] = "Erreur lors de la récupération des agendas Google : #{e.message}"
    end

    # Action pour vider un calendrier sélectionné
    def clear
      calendar_id = params[:calendar_id]
      GoogleCalendarService.new.clear_calendar(calendar_id)
      redirect_to admin_google_calendars_path, notice: "Tous les événements du calendrier sélectionné ont été supprimés avec succès."
    rescue => e
      redirect_to admin_google_calendars_path, alert: "Une erreur est survenue : #{e.message}"
    end
  end
  
end
