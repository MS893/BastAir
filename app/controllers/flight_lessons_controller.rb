require 'ostruct'

class FlightLessonsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_eleve!

  def index
    @lessons = FlightLesson.all.order(:id)
  end

  def show
    if params[:id] == "progression-type"
      @lesson = OpenStruct.new(title: "0. Progression type", id: "progression-type")
      @lesson_number = 0
    else
      @flight_lesson = FlightLesson.find(params[:id])
      @lesson = @flight_lesson
      # on calcule le numéro de la leçon en fonction de sa position dans la liste triée par ID
      @lesson_number = FlightLesson.where("id < ?", @flight_lesson.id).count + 1
    end

    padded_number = @lesson_number.to_s.rjust(2, '0')
    @pdf_available = Dir.glob(Rails.root.join('lib', 'assets', 'lecons', "#{padded_number}-*.pdf")).any?
  end

    def pdf
      if params[:id] == "progression-type"
        number = 0
      else
        lesson = FlightLesson.find(params[:id])
        number = FlightLesson.where("id < ?", lesson.id).count + 1
      end
  
      padded_number = number.to_s.rjust(2, '0')
      files = Dir.glob(Rails.root.join('lib', 'assets', 'lecons', "*#{padded_number}-*.pdf"))
  
      if files.any?
        send_file files.first, type: 'application/pdf', disposition: 'inline'
      else
        head :not_found
      end
    end


  
  private

  def authorize_eleve!
    redirect_to root_path, alert: "Cette section est réservée aux élèves et instructeurs." unless current_user.admin? || current_user.eleve? || current_user.instructeur?
  end

end