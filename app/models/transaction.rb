class Transaction < ApplicationRecord
  # == Associations ===========================================================
  # Une transaction peut être liée à un utilisateur (ex: cotisation d'un adhérent),
  # mais ce n'est pas obligatoire (ex: subvention, achat fournisseur).
  belongs_to :user, optional: true

  # == Enums ==================================================================
  # Définit des méthodes pratiques pour gérer les valeurs possibles de ces colonnes.
  # Par exemple, `transaction.recette?` ou `Transaction.recette` pour trouver toutes les recettes.
  ALLOWED_MVT = {
    recette: 'Recette',
    depense: 'Dépense'
  }

  ALLOWED_PYT = {
    virement: 'Virement',
    cheque: 'Chèque',
    especes: 'Espèces',
    carte: 'Carte bancaire',
    prelevement: 'Prélèvement sur compte'
  }

  ALLOWED_TSN = {
    adherent: 'Adhérent',
    subvention: 'Subvention',
    donateur: 'Donateur',
    fournisseur: 'Fournisseur',
    maintenance: 'Maintenance',
    charge: 'Charge',
    investissement: 'Investissement'
  }

  # == Validations ============================================================
  # S'assure que les données essentielles sont toujours présentes.
  validates :date_transaction, presence: true
  validates :description, presence: true, length: { minimum: 3 }
  validates :mouvement, presence: true, inclusion: { in: ALLOWED_MVT.values }
  validates :montant, presence: true, numericality: { greater_than: 0 }
  validates :source_transaction, presence: true, inclusion: { in: ALLOWED_TSN.values }
  validates :payment_method, presence: true, inclusion: { in: ALLOWED_PYT.values }

  # == Callbacks ==============================================================
  # Met à jour le solde de l'utilisateur après la création d'une transaction.
  after_initialize :set_default_date, if: :new_record?
  after_create :update_user_balance

  
  private

  # Définit la date du jour par défaut pour les nouvelles transactions.
  def set_default_date
    self.date_transaction ||= Date.today
  end

  def update_user_balance
    # On ne fait rien si la transaction n'est pas liée à un utilisateur.
    return if user.blank?

    # Détermine le montant à ajouter ou à soustraire.
    amount_to_change = (mouvement == 'Recette') ? montant : -montant

    # Utilise une transaction de base de données pour la sécurité.
    # lock! empêche les conditions de concurrence pendant la mise à jour du solde.
    user.with_lock do
      user.update!(solde: user.solde + amount_to_change)
    end
  end

end
