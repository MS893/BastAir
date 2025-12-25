# frozen_string_literal: true

class SignalementMailer < ApplicationMailer
  default from: 'no-reply@bastair.com'

  def new_signalement_notification(recipient, signalement)
    @recipient = recipient
    @signalement = signalement
    @user_who_reported = signalement.user
    @avion = signalement.avion
    mail(to: @recipient.email, subject: "Nouveau signalement sur l'avion #{@avion.immatriculation}")
  end
end
