class CreateTarifs < ActiveRecord::Migration[8.0]
  def change
    create_table :tarifs do |t|
      t.integer :annee
      t.integer :tarif_horaire_avion1
      t.integer :tarif_horaire_avion2
      t.integer :tarif_horaire_avion3
      t.integer :tarif_horaire_avion4
      t.integer :tarif_horaire_avion5
      t.integer :tarif_horaire_avion6
      t.integer :tarif_instructeur
      t.integer :tarif_simulateur
      t.integer :cotisation_club_m21
      t.integer :cotisation_club_p21
      t.integer :cotisation_autre_ffa
      t.integer :licence_ffa
      t.integer :licence_ffa_info_pilote
      t.integer :elearning_theorique
      t.integer :pack_pilote_m21
      t.integer :pack_pilote_p21

      t.timestamps
    end
  end
end
