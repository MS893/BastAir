class LivretController < ApplicationController
  before_action :authenticate_user!
  before_action :set_livret, only: [:update]

  def create
    # Not implemented yet
  end

  def update
    if @livret.update(livret_params)
      redirect_to livret_progression_path, notice: 'Mise à jour réussie.'
    else
      redirect_to livret_progression_path, alert: 'Mise à jour échouée.'
    end
  end

  private

  def set_livret
    @livret = Livret.find(params[:id])
  end

  def livret_params
    params.require(:livret).permit(:status)
  end
end