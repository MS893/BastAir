class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show]
  before_action :authorize_user, only: [:show]

  def show
    # Cette action rendra la vue app/views/users/show.html.erb
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
