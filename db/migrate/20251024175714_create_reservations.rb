# frozen_string_literal: true

class CreateReservations < ActiveRecord::Migration[8.0]
  def change
    create_table :reservations do |t|
      # une réservation est effectuée par un user et est lié à un avion
      t.references :user, foreign_key: { to_table: :users }
      t.references :avion, foreign_key: true

      t.datetime :start_time
      t.datetime :end_time
      t.string :summary                         # Le titre de la réservation
      t.text :description
      t.string :location
      t.text :attendees                         # tableau d'objets avec les emails des participants (il faudra le mettre au format json texte sérialisé)
      t.string :time_zone
      t.string :google_event_id
      t.string :google_instructor_event_id
      t.text :recurrence # Un tableau de chaînes définissant la répétition de l'événement (format [iCalendar RRULE])
      t.text :reminders_data, default: nil      # La gestion des rappels pour les participants (méthode et temps avant l'événement)
      t.string :status, default: 'confirmed'    # Le statut de l'événement (confirmed, tentative, cancelled)
      t.string :visibility, default: 'private'  # Pour contrôler qui voit les détails de la réservation sur le calendrier (default, public, private)
      t.text :conference_data, default: nil     # Informations pour la conférence vidéo (comme Google Meet)
      t.string :colorId, default: '1'           # L'ID pour définir la couleur de l'événement sur le calendrier (ex: '1', '2', '11')
      t.text :source                            # Informations sur la source de l'événement
      t.text :extended_properties, default: nil
      t.text :sharedExtendedProperties          # Très utile pour stocker des IDs internes (ex: l'ID de la réservation dans votre BD Rails) sans modifier les champs principaux.

      # champs supplémentaires de la réservation, à inclure dans description et attendees
      t.boolean :instruction
      t.string :fi
      t.string :type_vol # nav, mania, etc.

      t.timestamps
    end
  end
end

#
# attendees (qui est un tableau), ils peuvent être stockés en utilisant un champ text avec sérialisation/désérialisation en JSON.
#
# reminders	json texte sérialisé (ou text sérialisé)	= C'est un objet contenant un booléen (useDefault) et un tableau (overrides) de rappels. Le format json texte sérialisé vous permet de le stocker tel quel.
#
# conferenceData	json texte sérialisé (ou text sérialisé)	C'est un objet contenant les informations sur la conférence (ex: lien Google Meet). json texte sérialisé gère parfaitement cette structure.
#
# privateExtendedProperties	json texte sérialisé (ou text sérialisé)	C'est un objet de paires clé-valeur. Vous pouvez stocker l'objet complet. Alternativement, si vous n'y stockez que l'ID de votre réservation, un champ integer ou string séparé peut suffire.
#
# sharedExtendedProperties	json texte sérialisé (ou text sérialisé)	Similaire à privateExtendedProperties, mais partagé.
#
# source	json texte sérialisé (ou text sérialisé)	C'est un objet contenant le titre et l'URL source.
#
# status (Statut) : Le champ status vous permet de suivre le cycle de vie de la réservation, à la fois dans votre application Rails et dans Google Calendar.
# Format API Google : Chaîne de caractères (string).
# Valeurs courantes :confirmed : L'événement est validé.tentative : L'événement est provisoire (ex: attente de confirmation).cancelled : L'événement a été annulé (il reste visible, mais barré).
# Avantage pour votre projet :
# - Permet de filtrer et d'afficher l'état réel des réservations (ex: afficher "Annulé" sur le front-end).
# - Essentiel pour les mises à jour d'événements dans l'API (ex: passer de confirmed à cancelled).
# string (ou enum si vous souhaitez limiter les valeurs côté Rails).
#
# visibility (Visibilité) : Le champ visibility contrôle qui peut voir les détails de l'événement sur le calendrier de l'utilisateur.
# Format API Google : Chaîne de caractères (string).
# Valeurs courantes :
# default : Suit le paramètre par défaut du calendrier.
# public : Visible par tous ceux qui ont accès au calendrier.private : Seul le créateur et les invités explicites peuvent voir les détails.
# confidential : Un niveau de confidentialité plus strict.
# Avantage pour votre projet : Permet à votre application de définir si une réservation est interne ou peut être affichée publiquement.
# string (pour stocker la valeur exacte de l'API).
#
#
# model :
# class Reservation < ApplicationRecord
#   # Utilise la sérialisation pour convertir automatiquement le Hash/Array en JSON
#   # et le stocker dans le champ TEXT.
#
#   serialize :reminders_data, coder: JSON
#   serialize :conference_data, coder: JSON
#   serialize :extended_properties, coder: JSON
#   serialize :source_data, coder: JSON
#
#   # Autres associations et validations...
# end
#
#
