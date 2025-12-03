require 'csv'

class Vol < ApplicationRecord
  belongs_to :user
  belongs_to :avion

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
end