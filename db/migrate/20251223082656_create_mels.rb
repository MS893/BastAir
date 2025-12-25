# frozen_string_literal: true

class CreateMels < ActiveRecord::Migration[8.0]
  def change
    create_table :mels do |t|
      t.string :title_1
      t.string :title_2
      t.integer :installed
      t.integer :required
      t.string :tolerance

      t.timestamps
    end
  end
end
