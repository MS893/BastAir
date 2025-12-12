require 'csv'

class Vol < ApplicationRecord

  # Attributs pour le formulaire de saisie de la date et de l'heure pour les accepter sans essayer de les sauvegarder dans la table
  attr_accessor :debut_vol_date, :debut_vol_hour, :debut_vol_minute

  
  # == Associations ===========================================================
  belongs_to :user
  belongs_to :avion
  # == Callbacks ==============================================================
  before_save :calculate_fin_vol, if: -> { debut_vol.present? && duree_vol.present? }

  # Validation pour les compteurs
  validate :compteur_arrivee_superieur_au_depart
  # Validation pour s'assurer que le pilote a les qualifications requises
  validate :pilote_qualifie_pour_voler

  # Méthode pour générer le CSV à partir d'une collection de vols
  def self.to_csv(vols)
    # Définition des en-têtes de colonnes
    headers = ['Date', 'Pilote', 'Avion', 'Départ', 'Arrivée', 'Durée (centièmes)']

    CSV.generate(headers: true) do |csv|
      csv << headers

      # On itère sur la collection de vols fournie
      vols.each do |vol|
        csv << [
          vol.debut_vol.strftime('%d/%m/%Y %H:%M'),
          vol.user.name,
          vol.avion.immatriculation,
          vol.depart,
          vol.arrivee,
          vol.duree_vol
        ]
      end
    end
  end


  
  private

  # Calcule automatiquement l'heure de fin du vol avant la sauvegarde.
  def calculate_fin_vol
    duree_en_minutes = (duree_vol * 60).round
    self.fin_vol = debut_vol + duree_en_minutes.minutes
  end

  def compteur_arrivee_superieur_au_depart
    # On ne lance la validation que si les deux champs sont présents
    return if compteur_depart.blank? || compteur_arrivee.blank?

    if compteur_arrivee <= compteur_depart
      # Ajoute une erreur sur le champ 'compteur_arrivee' si la condition n'est pas respectée
      errors.add(:compteur_arrivee, "doit être supérieur au compteur de départ.")
    end
  end

  # S'assure que le pilote (user) a une licence et une visite médicale valides à la date du vol.
  def pilote_qualifie_pour_voler
    # On ne valide que si un utilisateur et une date sont associés au vol.
    # `debut_vol` semble être le champ de date/heure principal pour un vol.
    return if user.nil? || debut_vol.nil?

    # Vérification de la licence
    errors.add(:base, "Le pilote n'a pas de licence valide à la date du vol.") if user.date_licence.nil? || user.date_licence < debut_vol.to_date
    # Vérification de la visite médicale
    errors.add(:base, "Le pilote n'a pas de visite médicale valide à la date du vol.") if user.medical.nil? || user.medical < debut_vol.to_date
  end

end
