class Vol < ApplicationRecord
  belongs_to :user
  belongs_to :avion

  validates :compteur_arrivee, numericality: true,
            format: { with: /\A\d+(\.\d{1,2})?\z/, message: "doit avoir au maximum deux décimales" }

  validates :fuel_avant_vol, numericality: { greater_than_or_equal_to: 0 }
  validates :fuel_apres_vol, numericality: { greater_than_or_equal_to: 0 }
  validates :huile, numericality: { greater_than_or_equal_to: 0 }
  validates :nb_atterro, numericality: { greater_than: 0 }
  
end
