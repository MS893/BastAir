class FlightLessonsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_eleve!

  def index
    # Cette page est maintenant réservée aux élèves.
    # Vous pouvez ajouter ici la logique pour récupérer les leçons de vol de l'élève.
  end

end