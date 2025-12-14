class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protected

  # Surcharge de la méthode Devise pour rediriger systématiquement vers la page d'accueil après la connexion.
  def after_sign_in_path_for(resource)
    root_path
  end

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

  # Vérifie si l'utilisateur est un instructeur ou un administrateur
  def authorize_instructor_or_admin!
    redirect_to root_path, alert: "Accès réservé aux administrateurs et aux instructeurs." unless current_user&.admin? || current_user&.instructeur?
  end
  
end
