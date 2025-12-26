# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # pour passer du site français à anglais selon la locale choisie
  before_action :set_locale
  before_action :redirect_restricted_pages_in_english
  helper_method :restricted_page?

  protected

  # Surcharge de la méthode Devise pour rediriger systématiquement vers la page d'accueil après la connexion.
  def after_sign_in_path_for(_resource)
    root_path
  end

  private

  def redirect_restricted_pages_in_english
    # Si la langue est l'anglais et que l'on est sur une page restreinte
    if I18n.locale == :en && restricted_page?
      redirect_to root_path(locale: :en)
    end
  end

  def restricted_page?
    # Liste des conditions pour les pages non accessibles en anglais.
    # devise_controller? couvre le login, l'inscription, le mot de passe oublié, etc.
    # Vous pouvez ajouter d'autres contrôleurs si nécessaire (ex: 'users', 'members', etc.)
    devise_controller? || controller_name == 'users' ||
      (controller_name == 'static_pages' && %w[tarifs bia outils].include?(action_name))
  end

  def set_locale
    I18n.locale = if user_signed_in?
                    :fr
                  else
                    # Définit la locale à partir des paramètres ou utilise la valeur par défaut
                    params[:locale] || I18n.default_locale
                  end
  end

  def default_url_options
    # Ajoute le paramètre locale à toutes les URLs générées par l'application
    { locale: I18n.locale }
  end

  # Vérifie si l'utilisateur est un administrateur
  def authorize_admin!
    redirect_to root_path, alert: 'Accès réservé aux administrateurs.' unless current_user&.admin?
  end

  # Vérifie si l'utilisateur est un trésorier ou un administrateur
  def authorize_treasurer_or_admin!
    return if current_user&.admin? || current_user&.fonction == 'tresorier'

    redirect_to root_path,
                alert: 'Accès réservé aux administrateurs et au trésorier.'
  end

  # Vérifie si l'utilisateur est un instructeur ou un administrateur
  def authorize_instructor_or_admin!
    return if current_user&.admin? || current_user&.instructeur?

    redirect_to root_path,
                alert: 'Accès réservé aux administrateurs et aux instructeurs.'
  end

  # Vérifie si l'utilisateur est un élève, un instructeur ou un administrateur
  def authorize_student_area!
    return if current_user&.eleve? || current_user&.instructeur? || current_user&.admin?

    redirect_to root_path,
                alert: "Vous n'avez pas l'autorisation d'accéder à cette page."
  end
end
