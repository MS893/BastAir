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

    # Si la requête vient d'un Turbo Frame, on ne rend que la liste des résultats, sinon, on rend la page complète
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
    # Si la requête vient d'un Turbo Frame, on ne rend que le partiel des détails, sinon, on rend la page de profil complète (défaut)
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

    respond_to do |format|
      format.html do
        # Logique pour l'affichage HTML
        @vols = @user.vols.includes(:avion, :instructeur).order(debut_vol: :asc).page(params[:page]).per(13)
      end
      format.csv do
        # Logique pour l'export CSV
        start_date = Date.parse(params[:start_date])
        end_date = Date.parse(params[:end_date])
        vols_for_csv = @user.vols.where(debut_vol: start_date.beginning_of_day..end_date.end_of_day).order(debut_vol: :asc)
        send_data Vol.to_csv(vols_for_csv), filename: "carnet-de-vol-#{@user.nom.parameterize}-#{start_date}-#{end_date}.csv"
      end
    end

    # --- Calcul des totaux partiels si des dates sont fournies ---
    if params[:start_date].present? && params[:end_date].present?
      @start_date = Date.parse(params[:start_date])
      @end_date = Date.parse(params[:end_date])
      
      # On filtre les vols sur la période sélectionnée
      vols_in_period = @user.vols.where(debut_vol: @start_date.beginning_of_day..@end_date.end_of_day)
      
      # On stocke les résultats dans des variables dédiées aux totaux partiels
      @partial_totals = true
      @partial_total_duree_vol = vols_in_period.sum(:duree_vol)
      @partial_total_heures_cdb = vols_in_period.where(instructeur_id: nil).or(vols_in_period.where(type_vol: 'Instruction')).sum(:duree_vol)
      @partial_total_heures_double = vols_in_period.where.not(instructeur_id: nil).where.not(type_vol: 'Instruction').sum(:duree_vol)
      @partial_total_heures_instruction = @user.instructeur? ? vols_in_period.where(type_vol: 'Instruction').sum(:duree_vol) : 0
      @partial_total_atterrissages_jour = vols_in_period.where(nature: 'VFR de jour').sum(:nb_atterro)
      @partial_total_atterrissages_nuit = vols_in_period.where(nature: 'VFR de nuit').sum(:nb_atterro)
    end

    # --- Calcul des totaux pour la ligne de pied de page ---
    # On récupère TOUS les vols de l'utilisateur, sans pagination, pour les calculs
    all_user_vols = @user.vols

    # Total des heures de vol
    @total_duree_vol = all_user_vols.sum(:duree_vol)

    # Total des heures en tant que Commandant de Bord (CdB)
    @total_heures_cdb = all_user_vols.where(instructeur_id: nil).or(all_user_vols.where(type_vol: 'Instruction')).sum(:duree_vol)

    # Total des heures en double commande
    @total_heures_double = all_user_vols.where.not(instructeur_id: nil).where.not(type_vol: 'Instruction').sum(:duree_vol)

    # Total des heures d'instruction (uniquement si l'utilisateur est un instructeur)
    @total_heures_instruction = @user.instructeur? ? all_user_vols.where(type_vol: 'Instruction').sum(:duree_vol) : 0
    
    # Total des atterrissages de jour et de nuit
    @total_atterrissages_jour = all_user_vols.where(nature: 'VFR de jour').sum(:nb_atterro)
    @total_atterrissages_nuit = all_user_vols.where(nature: 'VFR de nuit').sum(:nb_atterro)

    # Totaux pour les conditions opérationnelles
    @total_heures_nuit = all_user_vols.where(nature: 'VFR de nuit').sum(:duree_vol)
    @total_heures_ifr = all_user_vols.where(nature: 'IFR').sum(:duree_vol)
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
    # Paramètres sensibles que seul un administrateur peut modifier
    # L'autorisation est vérifiée par `authorize_admin!` dans le `before_action`
    if current_user.admin?
      params.require(:user).permit(:admin, :fonction, :fi, :fe, :nuit, :google_calendar_id)
    else
      params.require(:user).permit() # Ne rien autoriser par défaut
    end
  end

  # Nouveaux "strong parameters" pour la mise à jour du profil
  def profile_params
    params.require(:user).permit(:email, :telephone, :adresse, :contact_urgence, :avatar)
  end
  
end
