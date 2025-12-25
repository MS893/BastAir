# frozen_string_literal: true

class AttendancesController < ApplicationController
  before_action :authenticate_user!

  def create
    @event = Event.find(params[:event_id])

    # Vérifie si l'utilisateur est déjà inscrit
    if @event.users.include?(current_user)
      redirect_to @event, alert: 'Vous êtes déjà inscrit à cet événement.'
      return
    end

    # Si l'événement est payant, on gère le débit du compte
    if @event.price.positive?
      # Vérifie si le solde de l'utilisateur est suffisant
      if current_user.solde < @event.price
        redirect_to @event,
                    alert: 'Votre solde est insuffisant pour vous inscrire à cet événement. Veuillez créditer votre compte.'
        return
      end

      # On utilise une transaction pour s'assurer que l'inscription et le débit se font ensemble
      ActiveRecord::Base.transaction do
        # On crée une transaction comptable pour le débit.
        # Le callback du modèle Transaction se chargera de mettre à jour le solde.
        Transaction.create!(
          user: current_user,
          description: "Inscription à l'événement '#{@event.title}'",
          mouvement: 'Dépense', # Une dépense pour l'utilisateur
          montant: @event.price,
          source_transaction: 'Charges Exceptionnelles', # TEMPORAIRE : À revoir avec une catégorie plus appropriée pour les frais d'inscription
          payment_method: 'Prélèvement sur compte'
        )
        @attendance = @event.attendances.create!(user: current_user)
      end

      # envoie un email de notification à l'organisateur
      UserMailer.new_participant_notification(@attendance).deliver_later
      redirect_to @event,
                  notice: "Félicitations ! Vous êtes inscrit à l'événement. Votre compte a été débité de #{@event.price} €."
    else
      # Si l'événement est gratuit, on crée simplement la participation
      @attendance = @event.attendances.new(user: current_user)
      if @attendance.save
        UserMailer.new_participant_notification(@attendance).deliver_later
        redirect_to @event, notice: "Félicitations ! Vous êtes inscrit à l'événement."
      else
        render 'events/show', status: :unprocessable_content
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    # Si la transaction échoue, on redirige avec un message d'erreur
    redirect_to @event, alert: "Une erreur est survenue lors de votre inscription : #{e.message}"
  end

  def destroy
    @event = Event.find(params[:event_id])
    attendance = current_user.attendances.find_by(event_id: @event.id)

    unless attendance
      redirect_to @event, alert: "Vous n'étiez pas inscrit à cet événement."
      return
    end

    # On empêche la désinscription si l'événement a déjà commencé
    if @event.start_date < Time.current
      redirect_to @event, alert: "Action impossible : l'événement a déjà commencé."
      return
    end

    # Si l'événement était payant, on rembourse l'utilisateur
    if @event.price.positive?
      ActiveRecord::Base.transaction do
        # On crée une transaction comptable pour le remboursement.
        # Le callback du modèle Transaction se chargera de mettre à jour le solde.
        Transaction.create!(
          user: current_user,
          description: "Remboursement - Désinscription de l'événement '#{@event.title}'",
          mouvement: 'Recette', # Une recette pour l'utilisateur
          montant: @event.price,
          source_transaction: 'Cotisations des Membres', # Mis à jour pour correspondre aux nouvelles catégories
          payment_method: 'Prélèvement sur compte' # Indique une opération interne
        )
        attendance.destroy!
      end
      redirect_to @event, notice: "Vous avez bien été désinscrit. Votre compte a été recrédité de #{@event.price} €."
    else
      attendance.destroy
      redirect_to @event, notice: "Vous avez bien été désinscrit de l'événement."
    end
  end
end
