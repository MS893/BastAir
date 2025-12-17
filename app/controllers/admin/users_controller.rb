module Admin
  class UsersController < ApplicationController
    before_action :authorize_admin!

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      if @user.save
        # On peut rediriger vers le profil du nouvel utilisateur ou la liste des utilisateurs
        redirect_to user_path(@user), notice: "L'adhérent a été créé avec succès."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def user_params
      # Paramètres de base pour la création d'un utilisateur
      base_params = params.require(:user).permit(:prenom, :nom, :email, :password, :password_confirmation, :date_naissance, :lieu_naissance, :profession, :adresse, :telephone, :contact_urgence, :num_ffa, :licence_type, :num_licence, :date_licence, :medical, :fe, :controle, :solde, :cotisation_club, :cotisation_ffa, :autorise)
      
      # Paramètres sensibles réservés aux admins, fusionnés séparément
      admin_params = params.require(:user).permit(:fonction, :admin, :fi)
      
      # On fusionne les deux listes de paramètres
      base_params.merge(admin_params)
    end
  end
end