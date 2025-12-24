class MaintenanceMailer < ApplicationMailer
  default from: 'no-reply@bastair.com' # Adaptez avec votre adresse d'envoi

  def low_potential_alert(avion)
    @avion = avion
    @admins = User.where(admin: true).pluck(:email)
    
    if @admins.any?
      mail(to: @admins, subject: "⚠️ Alerte Maintenance : Potentiel faible sur #{@avion.immatriculation}")
    end
  end

  def cen_alert(avion)
    @avion = avion
    @admins = User.where(admin: true).pluck(:email)
    
    if @admins.any?
      mail(to: @admins, subject: "⚠️ Alerte Maintenance : CEN expire bientôt sur #{@avion.immatriculation}")
    end
  end
end