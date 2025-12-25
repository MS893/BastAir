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

  # Action pour afficher la liste des signalements d'un avion (utilisé par Turbo Frame)
  def signalements_list
    @avion = Avion.find(params[:id])
    # On ne récupère que les signalements qui ne sont pas "résolus"
    @signalements = @avion.signalements.where.not(status: 'Résolu').order(created_at: :desc)

    # On vérifie si la requête vient de la modale (grâce au paramètre `source=modal`).
    if params[:source] == 'modal'
      # Si oui, on rend le partial simple pour la modale.
      render partial: 'signalements/list_for_modal'
    else
      # Sinon (cas de la page de réservation via Turbo Frame), on rend le partial
      # qui contient le turbo_frame_tag et la liste des signalements.
      render partial: 'signalements/show_for_reservation', locals: { signalements: @signalements }
    end
  end

end
