class Transaction < ApplicationRecord
  # == Associations ===========================================================
  # Une transaction peut être liée à un utilisateur (ex: cotisation d'un adhérent),
  # mais ce n'est pas obligatoire (ex: subvention, achat fournisseur).
  belongs_to :user, optional: true

  # Par défaut, n'affiche que les transactions non supprimées
  default_scope { where(deleted_at: nil) }
  # Permet de récupérer les transactions supprimées
  scope :discarded, -> { unscoped.where.not(deleted_at: nil) }

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

  # --- Libellés pour les recettes ---
  INCOME_SOURCES = {
    heures_vol: 'Heures de Vol / Location Avions',
    frais_instructeur: "Frais d'Instructeur",
    cotisations: 'Cotisations des Membres',
    subventions: "Subventions d'Exploitation",
    produits_manifestations: 'Produits Manifestations / Boutique',
    produits_financiers: 'Produits Financiers (Intérêts)',
    produits_exceptionnels: 'Produits Exceptionnels',
    reprises_amortissements: 'Reprises sur Amortissements'
  }.freeze

  # --- Libellés pour les dépenses ---
  EXPENSE_SOURCES = {
    achat_carburant: 'Achat Carburant (AvGas / Kérosène)',
    entretien_reparations: 'Entretien & Réparations Avions',
    assurances: 'Assurances (Flotte, Hangar)',
    loyer_redevances: 'Loyer Hangar / Redevances Aéronautiques',
    charges_personnel: 'Charges de Personnel (Salaires & Sociales)',
    fournitures_bureau: 'Fournitures de Bureau & Petit Matériel',
    frais_postaux_telecom: 'Frais Postaux & Télécommunications',
    impots_taxes: 'Impôts & Taxes (hors résultat)',
    frais_representation: 'Frais de Représentation & Réception',
    charges_interets: "Charges d'Intérêts d'Emprunt",
    charges_exceptionnelles: 'Charges Exceptionnelles',
    dotations_amortissements: 'Dotations aux Amortissements'
  }.freeze

  # On fusionne les deux listes pour la validation globale
  ALLOWED_TSN = INCOME_SOURCES.merge(EXPENSE_SOURCES).freeze

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
  after_destroy :reverse_user_balance_update

  # Méthodes pour la suppression logique (soft delete)
  def discard
    update(deleted_at: Time.current)
  end

  def restore
    update(deleted_at: nil)
  end

  def discarded?
    deleted_at.present?
  end
  


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
      # On utilise update_column pour modifier uniquement le solde sans déclencher
      # les autres validations du modèle User (ex: format du téléphone).
      user.update_column(:solde, user.solde + amount_to_change)
    end
  end

  # Met à jour le solde de l'utilisateur après la suppression d'une transaction.
  def reverse_user_balance_update
    # On ne fait rien si la transaction n'est pas liée à un utilisateur.
    return if user.blank?

    # On inverse le montant : si c'était une dépense (comme une pénalité), on recrédite (montant positif).
    # Si c'était une recette, on débite (-montant).
    amount_to_change = (mouvement == 'Recette') ? -montant : montant

    user.with_lock do
      user.update_column(:solde, user.solde + amount_to_change)
    end
  end

end
