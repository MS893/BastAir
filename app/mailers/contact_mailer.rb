# frozen_string_literal: true

class ContactMailer < ApplicationMailer
  default from: 'no-reply@bastair.com'

  def contact_email(nom, prenom, email, message)
    @nom = nom
    @prenom = prenom
    @email = email
    @message = message

    # Remplacez par l'adresse e-mail de l'administrateur du club
    mail(to: 'admin@bastair.com', subject: 'Nouvelle demande de contact pour un baptême')
  end
end
