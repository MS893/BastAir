# frozen_string_literal: true

module EventsHelper
  # Renvoie la classe CSS de l'icône Bootstrap correspondant au titre de l'événement
  def event_icon_class(event_title)
    case event_title
    when 'Pot'
      'bi-cup-straw'
    when 'Aide nettoyage locaux'
      'bi-stars'
    when 'Aide journée portes ouvertes'
      'bi-people'
    when 'Aide vols BIA'
      'bi-send'
    when 'Cours théorique'
      'bi-person-workspace'
    when 'Sortie club'
      'bi-airplane'
    else
      'bi-calendar-event' # icône par défaut pour les autres cas
    end
  end

  # classe de couleur Bootstrap correspondant au titre de l'événement
  def event_color_class(event_title)
    case event_title
    when 'Pot'
      'primary' # Bleu
    when 'Cours théorique'
      'info' # Cyan
    when 'Sortie club'
      'success' # Vert
    when 'Objets trouvés'
      'marron' # Marron défini dans le css
    when 'Aide nettoyage locaux'
      'bordeaux' # Bordeaux défini dans le css
    when 'Aide journée portes ouvertes'
      'violet' # Violet défini dans le css
    when 'Aide vols BIA'
      'turquoise' # Turquoise défini dans le css
    else
      'warning' # jaune
    end
  end
end
