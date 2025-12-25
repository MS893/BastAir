# frozen_string_literal: true

class CreateAttendances < ActiveRecord::Migration[8.0]
  def change
    create_table :attendances do |t|
      t.belongs_to :user, foreign_key: true
      t.belongs_to :event, foreign_key: true

      t.string :stripe_customer_id # identifiant unique donné par Stripe au payeur
      # index unique sur la paire [user_id, event_id]
      t.index %i[user_id event_id], unique: true

      t.timestamps
    end
  end
end
