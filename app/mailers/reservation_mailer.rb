class ReservationMailer < ApplicationMailer
  default from: 'no-reply@bastair.com'

  def aircraft_grounded_alert(reservation)
    @reservation = reservation
    @user = reservation.user
    @avion = reservation.avion
    
    mail(to: @user.email, subject: "⚠️ Attention : Avion indisponible pour votre réservation")
  end
end