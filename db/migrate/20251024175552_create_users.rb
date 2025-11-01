class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :prenom
      t.string :nom
      t.date :date_naissance
      t.string :lieu_naissance
      t.string :profession
      t.string :adresse
      t.string :telephone
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :contact_urgence
      t.string :num_ffa
      t.string :licence_type    # ATPL, CPL, PPL ou LAPL
      t.string :num_licence
      t.date :date_licence
      t.string :type_medical
      t.date :medical
      t.date :nuit
      t.date :fi
      t.date :fe
      t.date :controle
      t.decimal :solde, precision: 8, scale: 2, default: 0.0, null: false
      t.date :cotisation_club
      t.date :cotisation_ffa
      t.boolean :autorise
      t.boolean :admin, default: false, null: false
      t.string :fonction     # president, tresorier ou secretaire pour les admins, et eleve ou brevete pour les autres

      t.timestamps
    end
  end
end
