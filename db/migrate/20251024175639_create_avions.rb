class CreateAvions < ActiveRecord::Migration[8.0]
  def change
    create_table :avions do |t|
      #spécifications
      t.string :immatriculation
      t.string :marque
      t.string :modele
      t.string :moteur
      t.integer :conso_horaire

      # documents avion
      t.date :certif_immat
      t.date :cert_navigabilite
      t.date :cert_examen_navigabilite
      t.date :licence_station_aeronef
      t.date :cert_limitation_nuisances
      t.date :fiche_pesee
      t.date :assurance

      # maintenance avion
      t.date :_50h
      t.date :_100h
      t.date :annuelle
      t.date :gv
      t.date :tbo_helice
      t.date :tbo_parachute
      t.decimal :potentiel_cellule, precision: 7, scale: 2
      t.decimal :potentiel_moteur, precision: 7, scale: 2
      t.decimal :next_50h, precision: 5, scale: 2
      t.decimal :next_100h, precision: 5, scale: 2

      t.timestamps
    end
  end
end
