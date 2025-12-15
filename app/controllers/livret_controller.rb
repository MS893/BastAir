# app/controllers/livrets_controller.rb

class ElearningController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_student_area!, only: [:index, :show] # Seuls les élèves peuvent voir la liste et la page d'un cours
  before_action :set_course, only: [:show, :document]

  def show
    @livret = Livret.find(params[:id])
    # Active Storage est accessible directement via l'objet @livret
  end

  # Ou pour une liste :
  def index
    @livrets = Livret.all
  end

  def course_completion_params
    # Assurez-vous d'inclure :signature_data ici
    params.require(:course_completion).permit(:course_id, :user_id, :signature_data, :autres_champs...) 
  end

end
