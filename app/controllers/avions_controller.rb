class AvionsController < ApplicationController
  before_action :authenticate_user!

  # Action pour récupérer la dernière valeur du compteur d'un avion.
  def last_compteur
    avion = Avion.find(params[:id])
    # On cherche le dernier vol enregistré pour cet avion en se basant sur la valeur la plus élevée du compteur d'arrivée.
    # C'est la méthode la plus fiable pour obtenir la valeur de départ du prochain vol.
    last_vol = avion.vols.order(compteur_arrivee: :desc).first

    # On renvoie la valeur du compteur d'arrivée, ou une chaîne vide si aucun vol n'existe pour cet avion.
    render json: { compteur_depart: last_vol&.compteur_arrivee || '' }
  end

end
