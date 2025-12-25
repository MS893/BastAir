# frozen_string_literal: true

class InstructorAvailabilitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_if_instructor

  def edit
    # On récupère les disponibilités actuelles de l'instructeur
    @availabilities = current_user.instructor_availabilities.to_a
    # On prépare une structure pour faciliter l'affichage dans la vue
    @availability_grid = {}
    %w[lundi mardi mercredi jeudi vendredi samedi dimanche].each do |day|
      @availability_grid[day] = {
        'matin' => @availabilities.find { |a| a.day == day && a.period == 'matin' }.present?,
        'apres-midi' => @availabilities.find { |a| a.day == day && a.period == 'apres-midi' }.present?
      }
    end
  end

  def update
    # On récupère les créneaux cochés depuis le formulaire
    submitted_slots = params[:availabilities]&.keys || []

    # On supprime toutes les anciennes disponibilités de l'instructeur
    current_user.instructor_availabilities.destroy_all

    # On recrée uniquement les disponibilités pour les créneaux cochés
    submitted_slots.each do |slot|
      day, period = slot.split('-', 2) # On limite la division à 2 pour gérer "apres-midi"
      current_user.instructor_availabilities.create(day: day, period: period)
    end

    redirect_to agenda_instructeurs_path, notice: 'Vos disponibilités ont été mises à jour avec succès.'
  end

  # Action pour créer ou supprimer une disponibilité
  def toggle
    # Sécurité supplémentaire : si la qualification est expirée, on ne fait rien en base de données.
    if current_user.fi.present? && current_user.fi < Date.today
      render json: { status: 'expired', message: 'Qualification expirée, aucune action effectuée.' }, status: :forbidden
      return
    end

    if params[:available] == true
      # Crée la disponibilité si elle n'existe pas déjà (pour éviter les doublons)
      @availability = current_user.instructor_availabilities.find_or_create_by(
        day: params[:day],
        period: params[:period]
      )
      render json: { status: 'created', id: @availability.id }, status: :created
    else
      # Trouve et supprime la disponibilité
      @availability = current_user.instructor_availabilities.find_by(day: params[:day], period: params[:period])
      @availability&.destroy
      render json: { status: 'destroyed' }, status: :ok
    end
  end

  private

  def check_if_instructor
    # On vérifie maintenant si l'utilisateur a une date FI, même si elle est expirée,
    # pour permettre à la logique de la vue (afficher une alerte) de fonctionner sans être bloquée.
    render json: { error: 'Not authorized' }, status: :unauthorized unless current_user.fi.present?
  end
end
