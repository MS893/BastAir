# frozen_string_literal: true

class CreateNewsItems < ActiveRecord::Migration[8.0]
  def change
    create_table :news_items do |t|
      t.string :title
      t.text :content
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
