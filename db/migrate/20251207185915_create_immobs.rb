class CreateImmobs < ActiveRecord::Migration[8.0]
  def change
    create_table :immobs do |t|
      t.string :description
      t.date :date_acquisition
      t.decimal :valeur_acquisition, precision: 10, scale: 2
      t.integer :duree_amortissement # en années
      t.references :purchase_transaction, null: true, foreign_key: { to_table: :transactions }

      t.timestamps
    end
  end
end
