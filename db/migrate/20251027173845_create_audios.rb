# frozen_string_literal: true

class CreateAudios < ActiveRecord::Migration[8.0]
  def change
    create_table :audios do |t|
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
