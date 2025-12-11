class CreateInstructorAvailabilities < ActiveRecord::Migration[7.1]
  def change
    create_table :instructor_availabilities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :day, null: false
      t.string :period, null: false

      t.timestamps
    end
    add_index :instructor_availabilities, [:user_id, :day, :period], unique: true
  end
end
