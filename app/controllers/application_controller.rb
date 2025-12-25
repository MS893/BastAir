class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # pour passer du site français à anglais selon la locale choisie
  before_action :set_locale

  
  
  protected

  # Surcharge de la méthode Devise pour rediriger systématiquement vers la page d'accueil après la connexion.
  def after_sign_in_path_for(resource)
    root_path
  end



  private

  def set_locale
    if user_signed_in?
      I18n.locale = :fr
    else
      # Définit la locale à partir des paramètres ou utilise la valeur par défaut
      I18n.locale = params[:locale] || I18n.default_locale
    end
  end

  def default_url_options
    # Ajoute le paramètre locale à toutes les URLs générées par l'application
    { locale: I18n.locale }
  end

  # Vérifie si l'utilisateur est un administrateur
  def authorize_admin!
    redirect_to root_path, alert: "Accès réservé aux administrateurs." unless current_user&.admin?
  end

  # Vérifie si l'utilisateur est un trésorier ou un administrateur
  def authorize_treasurer_or_admin!
    redirect_to root_path, alert: "Accès réservé aux administrateurs et au trésorier." unless current_user&.admin? || current_user&.fonction == 'tresorier'
  end

  # Vérifie si l'utilisateur est un instructeur ou un administrateur
  def authorize_instructor_or_admin!
    redirect_to root_path, alert: "Accès réservé aux administrateurs et aux instructeurs." unless current_user&.admin? || current_user&.instructeur?
  end

  # Vérifie si l'utilisateur est un élève, un instructeur ou un administrateur
  def authorize_student_area!
    redirect_to root_path, alert: "Vous n'avez pas l'autorisation d'accéder à cette page." unless current_user&.eleve? || current_user&.instructeur? || current_user&.admin?
  end
  
end
