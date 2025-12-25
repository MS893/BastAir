# frozen_string_literal: true

class CreatePenalites < ActiveRecord::Migration[8.0]
  def change
    create_table :penalites do |t|
      # --- Qui est concerné ? ---
      t.references :user, foreign_key: true

      # --- Détails de la réservation annulée ---
      t.string :avion_immatriculation
      t.datetime :reservation_start_time
      t.datetime :reservation_end_time
      t.string :instructor_name

      # --- Détails de la pénalité ---
      t.text :cancellation_reason
      t.decimal :penalty_amount, precision: 8, scale: 2
      t.string :status, default: 'En attente' # 'En attente', 'Appliquée', 'Annulée'
      t.references :admin, foreign_key: { to_table: :users }, null: true
      t.text :admin_comment

      t.timestamps
    end
  end
end
