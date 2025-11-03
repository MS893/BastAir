# app/mailers/user_mailer.rb

class UserMailer < ApplicationMailer
  default from: 'no-reply@bastair.com'

  def new_participant_notification(attendance)
    @attendance = attendance
    @event = attendance.event
    @participant = attendance.user 
    @organizer = @event.admin || User.find_by(admin: true) # Plan B: trouver un admin général
    # Si, même après le plan B, aucun organisateur n'est trouvé, on n'envoie pas d'email
    # pour éviter de faire planter l'application.
    return unless @organizer
    # On prépare le nom de l'organisateur ici, en un seul endroit.
    @organizer_name = @organizer.name.presence || @organizer.email
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

  def welcome_email(user)
    @user = user
    mail(to: @user.email, subject: 'Bienvenue chez BastAir !')
  end

  def expiring_fi_summary(admins, instructors)
    @instructors = instructors
    admin_emails = admins.pluck(:email)
    mail(
      to: admin_emails,
      subject: "Résumé des qualifications d'instructeur arrivant à expiration"
    )
  end

  def flight_confirmation_email(vol, cost)
    @vol = vol
    @user = vol.user
    @cost = cost

    mail(
      to: @user.email,
      subject: "Confirmation de votre vol du #{vol.debut_vol.strftime('%d/%m/%Y')}"
    )
  end

end