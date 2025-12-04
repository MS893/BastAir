class AttendancesController < ApplicationController
  before_action :authenticate_user!

  def create
    @event = Event.find(params[:event_id])

    # Vérifie si l'utilisateur est déjà inscrit
    if @event.users.include?(current_user)
      redirect_to @event, alert: "Vous êtes déjà inscrit à cet événement."
      return
    end

    # Si l'événement est payant, on gère le débit du compte
    if @event.price > 0
      # Vérifie si le solde de l'utilisateur est suffisant
      if current_user.solde < @event.price
        redirect_to @event, alert: "Votre solde est insuffisant pour vous inscrire à cet événement. Veuillez créditer votre compte."
        return
      end

      # On utilise une transaction pour s'assurer que l'inscription et le débit se font ensemble
      ActiveRecord::Base.transaction do
        current_user.update!(solde: current_user.solde - @event.price)
        @attendance = @event.attendances.create!(user: current_user)
      end

      # envoie un email de notification à l'organisateur
      UserMailer.new_participant_notification(@attendance).deliver_later
      redirect_to @event, notice: "Félicitations ! Vous êtes inscrit à l'événement. Votre compte a été débité de #{@event.price} €."
    else
      # Si l'événement est gratuit, on crée simplement la participation
      @attendance = @event.attendances.new(user: current_user)
      if @attendance.save
        UserMailer.new_participant_notification(@attendance).deliver_later
        redirect_to @event, notice: "Félicitations ! Vous êtes inscrit à l'événement."
      else
        render 'events/show', status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    # Si la transaction échoue, on redirige avec un message d'erreur
    redirect_to @event, alert: "Une erreur est survenue lors de votre inscription : #{e.message}"
  end

  def destroy
    @event = Event.find(params[:event_id])
    attendance = current_user.attendances.find_by(event_id: @event.id)

    if attendance
      attendance.destroy
      redirect_to @event, notice: "Vous avez bien été désinscrit de l'événement."
    else
      redirect_to @event, alert: "Vous n'étiez pas inscrit à cet événement."
    end
  end

end