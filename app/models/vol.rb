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

  # Callback pour facturer le vol juste après sa création
  after_create :process_flight_billing


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

  # Méthode principale pour la facturation, appelée par le callback after_create
  def process_flight_billing
    cost = calculate_cost
    return if cost <= 0 # Ne rien faire si le coût est nul ou négatif

    # Utilise une transaction pour s'assurer que les deux opérations (débit et création de transaction)
    # réussissent ou échouent ensemble, garantissant l'intégrité des données.
    ApplicationRecord.transaction do
      # Créer l'enregistrement comptable. Le callback `after_create` du modèle Transaction
      # se chargera de mettre à jour le solde de l'utilisateur.
      Transaction.create!(
        user: user,
        date_transaction: self.debut_vol.to_date,
        description: "#{self.avion.immatriculation} (#{self.duree_vol.to_s}h)",
        mouvement: 'Dépense',
        montant: cost,
        payment_method: 'Prélèvement sur compte',
        is_checked: true, # La transaction est automatiquement vérifiée car interne
        source_transaction: 'Adhérent' # Utilise une valeur valide de l'enum Transaction::ALLOWED_TSN
      )
    end

    # 3. Envoyer l'email de confirmation (en dehors de la transaction)
    UserMailer.flight_confirmation_email(self, cost).deliver_later
  end

  # Calcule le coût total du vol en se basant sur les tarifs actuels
  def calculate_cost
    tarif = Tarif.order(annee: :desc).first
    return 0 unless tarif

    # On utilise le tarif horaire de l'avion spécifique du vol.
    # Pour l'instant, on suppose que c'est tarif_horaire_avion1, mais cette logique
    # devra être adaptée si vous avez plusieurs tarifs d'avions.
    flight_cost = self.duree_vol * tarif.tarif_horaire_avion1
    flight_cost += self.duree_vol * tarif.tarif_instructeur if user.eleve? && !self.solo
    flight_cost
  end
  
end
