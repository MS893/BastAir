# db/migrate/YYYYMMDDHHMMSS_create_signalements.rb
class CreateSignalements < ActiveRecord::Migration[8.0]
  def change
    create_table :signalements do |t|
      t.references :user, null: false, foreign_key: true
      t.references :avion, null: false, foreign_key: true

      t.text :description, null: false
      t.string :status, null: false, default: 'Ouvert'

      t.timestamps
    end
  end
end
