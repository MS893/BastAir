# frozen_string_literal: true

class Admin::ReservationsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!

  def index
    # On commence par la portée de base
    @reservations = Reservation.includes(:user, :avion).order(start_time: :desc)

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

    # On synchronise la suppression avec Google Calendar
    GoogleCalendarService.new.delete_event_for_app(@reservation)

    @reservation.destroy
    redirect_to admin_reservations_path, notice: 'La réservation a été supprimée avec succès.', status: :see_other
  end
end
