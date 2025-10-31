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
    carte: 'Carte bancaire'
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

end
