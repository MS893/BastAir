class CreateQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :questions do |t|
      t.text :qcm
      t.string :answer_1
      t.string :answer_2
      t.string :answer_3
      t.string :answer_4
      t.integer :correct_answer

      t.references :course, null: false, foreign_key: true

      t.timestamps
    end
  end
end
