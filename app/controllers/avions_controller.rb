class AvionsController < ApplicationController
  before_action :authenticate_user!

  def last_compteur
    avion = Avion.find(params[:id])
    # On cherche le dernier vol enregistré pour cet avion
    last_vol = avion.vols.order(created_at: :desc).first
    # On renvoie la valeur du compteur d'arrivée, ou une chaîne vide si aucun vol n'existe
    compteur = last_vol ? last_vol.compteur_arrivee : ''
    render json: { compteur_depart: compteur }
  end

end