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

  # Notification d'annulation de réservation
  def reservation_cancelled_notification(user, reservation)
    @user = user
    @reservation = reservation
    mail(to: @user.email, subject: 'Confirmation d\'annulation de votre réservation')
  end
    
  # Notification d'une tentative d'annulation tardive à un admin
  def late_cancellation_attempt_notification(admin, user, reservation)
    @admin = admin
    @user = user
    @reservation = reservation
    mail(to: @admin.email, subject: "Alerte : Tentative d'annulation tardive")
  end

  # Notification d'une annulation tardive (< 48h) à un admin
  def late_cancellation_notification(admin, user, reservation, reason)
    @admin = admin
    @user = user
    @reservation = reservation
    @reason = reason
    mail(to: @admin.email, subject: "Info : Annulation tardive de réservation")
  end

  # Notification d'une annulation tardive (< 48h) à un instructeur
  def late_cancellation_notification_to_instructor(instructor, user, reservation, reason)
    @instructor = instructor
    @user = user
    @reservation = reservation
    @reason = reason
    mail(to: @instructor.email, subject: "Info : Annulation d'un vol en instruction")
  end

  # Notification à l'utilisateur qu'une pénalité a été appliquée
  def penalty_applied_notification(user, penalite)
    @user = user
    @penalite = penalite
    mail(to: @user.email, subject: "Application d'une pénalité pour annulation tardive")
  end

  def negative_balance_email(user)
    @user = user
    mail(to: @user.email, subject: 'Alerte : Votre solde de compte est négatif')
  end

  def welcome_email(user)
    @user = user
    mail(to: @user.email, subject: "Bienvenue à l'aéroclub Bast'Air !")
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

  # Envoie une notification de taxe d'atterrissage aux administrateurs et au trésorier
  def landing_tax_notification(recipient_emails, pilot, vol, tax_status, tax_aerodrome)
    @pilot = pilot
    @vol = vol
    @tax_status = tax_status
    @tax_aerodrome = tax_aerodrome

    return if recipient_emails.empty?

    mail(to: recipient_emails, subject: "Taxe d'atterrissage : #{@pilot.name} à #{@tax_aerodrome}")
  end

end