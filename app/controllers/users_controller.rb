class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show]
  before_action :authorize_user, only: [:show]
  
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
    # @user est déjà défini par le before_action
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
