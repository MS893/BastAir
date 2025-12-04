require 'csv'

class Vol < ApplicationRecord
  belongs_to :user
  belongs_to :avion
  # Validation personnalisée pour les compteurs
  validate :compteur_arrivee_superieur_au_depart

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

  def compteur_arrivee_superieur_au_depart
    # On ne lance la validation que si les deux champs sont présents
    return if compteur_depart.blank? || compteur_arrivee.blank?

    if compteur_arrivee <= compteur_depart
      # Ajoute une erreur sur le champ 'compteur_arrivee' si la condition n'est pas respectée
      errors.add(:compteur_arrivee, "doit être supérieur au compteur de départ.")
    end
  end

end
