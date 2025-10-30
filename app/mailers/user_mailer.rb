class UserMailer < ApplicationMailer
  default from: 'no-reply@bastair.com'

  def welcome_email(user)
    @user = user
    mail(to: @user.email, subject: 'Bienvenue chez BastAir !')
  end

  def new_participant_notification(attendance)
    @attendance = attendance
    @event = attendance.event
    @participant = attendance.user
    @organizer = @event.admin
    mail(to: @organizer.email, subject: "Nouveau participant à votre événement : #{@event.title}")
  end

  def event_updated_notification(participant, event)
    @participant = participant
    @event = event
    mail(to: @participant.email, subject: "Mise à jour de l'événement : #{@event.title}")
  end

  def event_destroyed_notification(participant, event_title, was_paid)
    @participant = participant
    @event_title = event_title
    @was_paid = was_paid
    mail(to: @participant.email, subject: "Annulation de l'événement : #{@event_title}")
  end

  def negative_balance_email(user)
    @user = user
    mail(to: @user.email, subject: 'Alerte : Votre solde de compte est négatif')
  end
end