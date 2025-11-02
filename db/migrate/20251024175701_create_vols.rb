class CreateVols < ActiveRecord::Migration[8.0]
  def change
    create_table :vols do |t|
      # un vol est effectué par un user et est lié à un avion
      t.references :user, foreign_key: { to_table: :users }
      t.references :avion, foreign_key: true
      
      t.string :type_vol        , null: false, default: 'Standard'  # standard, vol découverte, vol d'initiation, vol d'essai, convoyage, vol BIA
      t.string :depart          , null: false                       # aérodrome de départ
      t.string :arrivee         , null: false                       # aérodrome d'arrivée
      t.datetime :debut_vol     , null: false
      t.datetime :fin_vol       , null: false
      t.float :compteur_depart  , precision: 7, scale: 2, null: false
      t.float :compteur_arrivee , precision: 7, scale: 2, null: false
      t.float :duree_vol        , precision: 4, scale: 2, null: false
      t.integer :nb_atterro     , precision: 2, null: false, default: 1, null: false
      t.boolean :solo           , null: false, default: false
      t.boolean :supervise      , null: false, default: false
      t.boolean :nav            , null: false, default: false
      t.string :nature          , null: false, default: 'VFR de jour'
      t.float :fuel_avant_vol   , precision: 5, scale: 2, default: 0.0, null: false
      t.float :fuel_apres_vol   , precision: 5, scale: 2, default: 0.0, null: false
      t.float :huile            , precision: 2, scale: 1, default: 0.0, null: false

      t.timestamps
    end
  end
end
