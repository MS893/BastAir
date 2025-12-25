# frozen_string_literal: true

class CreateCourses < ActiveRecord::Migration[8.0]
  def change
    create_table :courses do |t|
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
