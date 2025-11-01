class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  # Vérifie si l'utilisateur est un administrateur
  def authorize_admin!
    redirect_to root_path, alert: "Accès réservé aux administrateurs." unless current_user&.admin?
  end

  # Vérifie si l'utilisateur est un élève (ou un admin, qui a tous les droits)
  def authorize_eleve!
    redirect_to root_path, alert: "Cette section est réservée aux élèves." unless current_user&.fonction == 'eleve' || current_user&.admin?
  end

  # Vérifie si l'utilisateur est un trésorier ou un administrateur
  def authorize_treasurer_or_admin!
    redirect_to root_path, alert: "Accès réservé aux administrateurs et au trésorier." unless current_user&.admin? || current_user&.fonction == 'tresorier'
  end
end
