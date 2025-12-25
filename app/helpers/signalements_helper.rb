# frozen_string_literal: true

module SignalementsHelper
  # Renvoie la classe CSS Bootstrap pour la couleur du badge en fonction du statut du signalement.
  def signalement_status_badge_class(status)
    case status
    when 'Ouvert'
      'bg-danger' # Rouge
    when 'En cours'
      'bg-warning text-dark' # Jaune (avec texte noir pour le contraste)
    when 'Résolu'
      'bg-success' # Vert
    else
      'bg-secondary' # Gris pour tout autre statut
    end
  end
end
