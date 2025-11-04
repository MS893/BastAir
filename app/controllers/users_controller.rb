class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show]
  before_action :authorize_user, only: [:show]
  before_action :authorize_admin!, only: [:index] # Seuls les admins peuvent voir la liste
  
  def index
    @users = User.order(:nom, :prenom)
    if params[:query].present?
      @users = @users.where("LOWER(nom) LIKE LOWER(?) OR LOWER(prenom) LIKE LOWER(?)", "%#{params[:query]}%", "%#{params[:query]}%")
    end

    # Si la requête vient d'un Turbo Frame, on ne rend que la liste des résultats.
    # Sinon, on rend la page complète.
    if turbo_frame_request?
      render(partial: "users/user_list", locals: { users: @users })
    else
      # Comportement normal pour le chargement initial de la page
    end
  end

  # Action pour la recherche d'utilisateurs en autocomplétion
  def search
    @users = User.order(:nom, :prenom)
    if params[:query].present?
      # Recherche insensible à la casse sur le nom et le prénom
      @users = @users.where("LOWER(nom) LIKE LOWER(?) OR LOWER(prenom) LIKE LOWER(?)", "%#{params[:query]}%", "%#{params[:query]}%")
    end
    # On rend une vue partielle sans le layout global
    render partial: "users/search_results", locals: { users: @users }
  end

  def show
    # Si la requête vient d'un Turbo Frame, on ne rend que le partiel des détails.
    # Sinon, on rend la page de profil complète (comportement par défaut).
    if turbo_frame_request? && turbo_frame_request_id == 'user_details'
      render partial: 'user_details', locals: { user: @user }
    end
    # Si ce n'est pas une requête Turbo Frame, Rails rendra implicitement `show.html.erb`.
  end

  
  private
  
  def set_user
    @user = User.find(params[:id])
  end

  def authorize_user
    unless current_user == @user || current_user.admin?
      redirect_to root_path, alert: "Vous n'êtes pas autorisé à voir cette page."
    end
  end
  
end
