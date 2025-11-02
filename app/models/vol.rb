class Vol < ApplicationRecord
  belongs_to :user
  belongs_to :avion
  # Un vol peut avoir un instructeur, mais ce n'est pas obligatoire (optional: true)
  belongs_to :instructeur, class_name: 'User', foreign_key: 'instructeur_id', optional: true

  validates :compteur_arrivee, numericality: true,
            format: { with: /\A\d+(\.\d{1,2})?\z/, message: "doit avoir au maximum deux décimales" }

  validates :fuel_avant_vol, numericality: { greater_than_or_equal_to: 0 }
  validates :fuel_apres_vol, numericality: { greater_than_or_equal_to: 0 }
  validates :huile, numericality: { greater_than_or_equal_to: 0 }
  validates :nb_atterro, numericality: { greater_than: 0 }

  # Validation personnalisée pour s'assurer que le compteur d'arrivée est supérieur au compteur de départ
  validate :compteur_arrivee_must_be_greater_than_depart

  # Validation pour s'assurer qu'un élève a toujours un instructeur
  validate :instructor_required_for_student

  private

  def compteur_arrivee_must_be_greater_than_depart
    return if compteur_depart.blank? || compteur_arrivee.blank?
  
    errors.add(:compteur_arrivee, "doit être supérieur au compteur de départ") if compteur_arrivee <= compteur_depart
  end

  def instructor_required_for_student
    # Si l'utilisateur est un élève et qu'il n'y a pas d'instructeur sélectionné
    if user&.eleve? && instructeur_id.blank?
      errors.add(:instructeur_id, "doit être sélectionné pour un vol d'élève")
    end
  end
end
