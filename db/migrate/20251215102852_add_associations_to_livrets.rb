class AddAssociationsToLivrets < ActiveRecord::Migration[8.0]
  def change
    add_reference :livrets, :user, null: false, foreign_key: true
    add_reference :livrets, :course, null: false, foreign_key: true
  end
end
