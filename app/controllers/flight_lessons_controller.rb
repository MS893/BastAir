# frozen_string_literal: true

class FlightLessonsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_eleve!

  def index
    @lessons = FlightLesson.order(:id)
  end

  def show
    if params[:id] == 'progression-type'
      @lesson = Struct.new(:title, :id).new('0. Progression type', 'progression-type')
      @lesson_number = 0
    else
      @flight_lesson = FlightLesson.find(params[:id])
      @lesson = @flight_lesson
      # on calcule le numéro de la leçon en fonction de sa position dans la liste triée par ID
      @lesson_number = FlightLesson.where(id: ...@flight_lesson.id).count + 1
    end

    padded_number = @lesson_number.to_s.rjust(2, '0')
    @pdf_available = Rails.root.glob("lib/assets/lecons/#{padded_number}-*.pdf").any?
  end

  def pdf
    if params[:id] == 'progression-type'
      number = 0
    else
      lesson = FlightLesson.find(params[:id])
      number = FlightLesson.where(id: ...lesson.id).count + 1
    end

    padded_number = number.to_s.rjust(2, '0')
    files = Rails.root.glob("lib/assets/lecons/*#{padded_number}-*.pdf")

    if files.any?
      send_file files.first, type: 'application/pdf', disposition: 'inline'
    else
      head :not_found
    end
  end

  private

  def authorize_eleve!
    return if current_user.admin? || current_user.eleve? || current_user.instructeur?

    redirect_to root_path,
                alert: 'Cette section est réservée aux élèves et instructeurs.'
  end
end
