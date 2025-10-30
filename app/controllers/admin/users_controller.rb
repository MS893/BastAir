module Admin
  class UsersController < ApplicationController
    before_action :authorize_admin!

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      if @user.save
        # Vous pouvez choisir de rediriger vers le profil du nouvel utilisateur ou la liste des utilisateurs
        redirect_to user_path(@user), notice: "L'adhérent a été créé avec succès."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def user_params
      # Liste de tous les champs autorisés pour la création d'un utilisateur
      params.require(:user).permit(:prenom, :nom, :email, :password, :password_confirmation, :date_naissance, :lieu_naissance, :profession, :adresse, :telephone, :contact_urgence, :num_ffa, :licence_type, :num_licence, :date_licence, :medical, :fi, :fe, :controle, :solde, :cotisation_club, :cotisation_ffa, :autorise, :fonction, :admin)
    end
  end
end