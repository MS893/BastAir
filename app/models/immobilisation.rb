class Immobilisation < ApplicationRecord
  belongs_to :purchase_transaction, class_name: 'Transaction', optional: true

  self.table_name = 'immobs' # immobilisations/amortissements
  validates :description, presence: true
  validates :date_acquisition, presence: true
  validates :valeur_acquisition, presence: true, numericality: { greater_than: 0 }
  validates :duree_amortissement, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :date_acquisition_cannot_be_in_the_future

  # Calcule l'amortissement annuel selon la méthode linéaire
  def amortissement_annuel
    valeur_acquisition / duree_amortissement
  end

  # Calcule le total des amortissements déjà pratiqués jusqu'à une année donnée
  def amortissements_cumules(annee)
    # On ne compte que les années pleines depuis l'acquisition
    annees_amorties = [0, annee - date_acquisition.year].max
    (amortissement_annuel * annees_amorties).round(2)
  end


  
  private

  def date_acquisition_cannot_be_in_the_future
    if date_acquisition.present? && date_acquisition > Date.today
      errors.add(:date_acquisition, "ne peut pas être dans le futur")
    end
  end
  
end
