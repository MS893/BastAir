# frozen_string_literal: true

module Admin
  class ReservationsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_admin!

    def index
      # On commence par la portée de base (on affiche par ordre croissant de date)
      @reservations = Reservation.includes(:user, :avion).order(start_time: :asc)

      # On récupère les utilisateurs et avions qui ont des réservations pour les filtres
      @users = User.where(id: Reservation.distinct.pluck(:user_id)).order(:nom, :prenom)
      @avions = Avion.where(id: Reservation.distinct.pluck(:avion_id)).order(:immatriculation)

      # On applique les filtres si les paramètres sont présents
      @reservations = @reservations.where(user_id: params[:user_id]) if params[:user_id].present?
      @reservations = @reservations.where(avion_id: params[:avion_id]) if params[:avion_id].present?

      # On pagine les résultats filtrés
      @reservations = @reservations.page(params[:page]).per(20)
    end

    def destroy
      @reservation = Reservation.find(params[:id])

      # --- Synchronisation de la suppression avec Google Calendar ---
      # On instancie le service une seule fois.
      calendar_service = GoogleCalendarService.new

      # 1. Si c'est un vol en instruction, on supprime l'événement de l'agenda de l'instructeur.
      if @reservation.instruction? && @reservation.fi.present?
        Rails.logger.info "Tentative de suppression de l'événement de l'instructeur pour la réservation ##{@reservation.id}..."
        calendar_service.delete_instructor_event(@reservation)
      end

      # 2. On supprime l'événement principal de l'agenda de l'avion.
      # Cette méthode utilise le `google_event_id` stocké sur la réservation.
      Rails.logger.info "Tentative de suppression de l'événement principal (avion) pour la réservation ##{@reservation.id}..."
      calendar_service.delete_event_for_app(@reservation)

      return unless @reservation.destroy

      respond_to do |format|
        # Comportement classique pour les navigateurs sans JavaScript
        format.html { redirect_to admin_reservations_path, notice: 'La réservation a été supprimée avec succès.' }
        # Réponse pour les requêtes Turbo : envoie plusieurs instructions (suppression et affichage du flash)
        format.turbo_stream do
          flash.now[:notice] = 'La réservation a été supprimée avec succès.'
          render turbo_stream: [
            turbo_stream.remove(@reservation),
            turbo_stream.update('flash-messages', partial: 'layouts/flash')
          ]
        end
      end
    end
  end
end
