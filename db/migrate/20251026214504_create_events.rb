# frozen_string_literal: true

class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.belongs_to :admin, foreign_key: { to_table: :users }

      t.datetime :start_date
      t.string :duration      # représentant le nombre d'heures:minutes
      t.string :title
      t.text :description
      t.integer :price        # correspond au nombre d'euros que coûte l'événement
      t.string :google_event_id

      t.timestamps
    end
  end
end
