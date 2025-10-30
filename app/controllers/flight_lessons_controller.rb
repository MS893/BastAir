class FlightLessonsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_eleve!

  def index
    @lessons = FlightLesson.all.order(:id)
  end

  def show
    @lesson = FlightLesson.find(params[:id])
  end

end