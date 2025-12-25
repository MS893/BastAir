# frozen_string_literal: true

class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.string :var, null: false, index: { unique: true }
      t.text :val

      t.timestamps
    end
  end
end
