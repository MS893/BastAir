class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.belongs_to :user, foreign_key: true

      t.date :date_transaction                      # Date de l'encaissement/décaissement
      t.string :description                         # Libellé de l'opération (cotisation, achat, loyer, salaire, communication, etc.)
      t.string :mouvement                           # 'Recette' ou 'Dépense'
      t.decimal :montant, precision: 8, scale: 2    # Montant de l'opération (en euros)
      t.string :piece_justificative                 # Référence de la facture ou du chèque
      t.string :payment_method                      # Mode de paiement (ex. : Virement, Chèque, Espèces, Carte Bancaire)
      t.boolean :is_checked                         # Permet au trésorier de marquer une transaction comme ayant été vérifiée et rapprochée du relevé bancaire
      t.string :source_transaction                  # Qui a payé / Qui a été payé ? (ex. : Nom du fournisseur, de l'adhérent, de l'organisme subventionneur)
      t.string :attachment_url                      # Lien vers la pièce justificative (vers DRIVE et le PDF de la facture ou du reçu numérisé)
      
      t.timestamps
    end
  end
end
