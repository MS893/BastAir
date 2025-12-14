class FlightLessonsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_eleve!

  def index
    @lessons = FlightLesson.all.order(:id)
  end

  def show
    @lesson = FlightLesson.find(params[:id])
  end


  
  private

  def authorize_eleve!
    redirect_to root_path, alert: "Cette section est réservée aux élèves et instructeurs." unless current_user.admin? || current_user.eleve? || current_user.instructeur?
  end

end