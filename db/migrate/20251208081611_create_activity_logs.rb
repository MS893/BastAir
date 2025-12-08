class CreateActivityLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action
      t.string :record_type
      t.integer :record_id
      t.text :details

      t.timestamps
    end
  end
end
