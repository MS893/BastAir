class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :update, :update_profil]
  before_action :authorize_user, only: [:show, :update_profil]
  before_action :authorize_admin!, only: [:index, :update] # Seuls les admins peuvent voir la liste des users et mettre à jour les rôles

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
      # On vérifie si le contact d'urgence est invalide pour afficher une alerte.
      # L'alerte ne s'affiche que si l'utilisateur consulte son propre profil.
      if @user == current_user && @user.contact_urgence.present? && !@user.valid?(:update_profil)
        flash.now[:warning] = "Votre numéro de contact d'urgence semble invalide. #{view_context.link_to('Veuillez le corriger ici', edit_profil_user_path(@user))}".html_safe
      end

      # On vérifie les validités qui expirent bientôt
      validity_warnings = @user.validity_warnings
      if @user == current_user && validity_warnings.any?
        # On combine les avertissements en un seul message flash.
        flash.now[:info] = validity_warnings.join('<br>').html_safe
      end

      render partial: 'user_details', locals: { user: @user }
    end
    # Si ce n'est pas une requête Turbo Frame, Rails rendra implicitement `show.html.erb`.
  end

  # Action pour afficher la liste des vols d'un utilisateur spécifique
  def vols
    @user = User.find(params[:id])
    authorize_user # On s'assure que l'utilisateur a le droit de voir cette page
    @vols = @user.vols.order(debut_vol: :desc).page(params[:page]).per(20)
  end

  def update
    if @user.update(user_params)
      redirect_to users_path, notice: "Les rôles de l'utilisateur #{@user.full_name} ont été mis à jour avec succès."
    else
      render :show, status: :unprocessable_entity
    end
  end

  # Nouvelle action pour la mise à jour du profil par l'utilisateur lui-même
  def update_profil
    if @user.update(profile_params)
      redirect_to user_path(@user), notice: "Votre profil a été mis à jour avec succès."
    else
      # En cas d'erreur, on affiche à nouveau la page d'édition
      render 'edit_profil', status: :unprocessable_entity
    end
  end

  
  private

  def set_user
    @user = User.find(params[:id]) # @user est déjà défini ici, pas besoin de current_user
  end

  def authorize_user
    unless current_user == @user || current_user.admin?
      redirect_to root_path, alert: "Vous n'êtes pas autorisé à voir cette page."
    end
  end

  def user_params
    # Permet aux administrateurs de mettre à jour le statut admin, la fonction et la date FI
    params.require(:user).permit(:admin, :fonction, :fi)
  end

  # Nouveaux "strong parameters" pour la mise à jour du profil
  def profile_params
    params.require(:user).permit(:email, :telephone, :adresse, :contact_urgence, :avatar)
  end
  
end
