# app/controllers/admin/base_controller.rb

class Admin::BaseController < ApplicationController
  # On s'assure que l'utilisateur est connecté avant toute action
  before_action :authenticate_user!
  # On vérifie que l'utilisateur est un administrateur
  before_action :check_admin

  private

  def check_admin
    redirect_to root_path, alert: "Accès non autorisé." unless current_user.admin?
  end
  
end
