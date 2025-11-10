# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_11_09_191626) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "attendances", force: :cascade do |t|
    t.integer "user_id"
    t.integer "event_id"
    t.string "stripe_customer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_attendances_on_event_id"
    t.index ["user_id", "event_id"], name: "index_attendances_on_user_id_and_event_id", unique: true
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "audios", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "avions", force: :cascade do |t|
    t.string "immatriculation"
    t.string "marque"
    t.string "modele"
    t.integer "conso_horaire"
    t.date "certif_immat"
    t.date "cert_navigabilite"
    t.date "cert_examen_navigabilite"
    t.date "licence_station_aeronef"
    t.date "cert_limitation_nuisances"
    t.date "fiche_pesee"
    t.date "assurance"
    t.date "_50h"
    t.date "_100h"
    t.date "annuelle"
    t.date "gv"
    t.date "helice"
    t.date "parachute"
    t.float "potentiel_cellule"
    t.float "potentiel_moteur"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "courses", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "events", force: :cascade do |t|
    t.integer "admin_id"
    t.datetime "start_date"
    t.string "duration"
    t.string "title"
    t.text "description"
    t.integer "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_events_on_admin_id"
  end

  create_table "flight_lessons", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reservations", force: :cascade do |t|
    t.integer "user_id"
    t.integer "avion_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "summary"
    t.text "description"
    t.string "location"
    t.text "attendees"
    t.string "time_zone"
    t.string "google_event_id"
    t.text "recurrence"
    t.text "reminders_data"
    t.string "status", default: "confirmed"
    t.string "visibility", default: "private"
    t.text "conference_data"
    t.string "colorId", default: "1"
    t.text "source"
    t.text "extended_properties"
    t.text "sharedExtendedProperties"
    t.boolean "instruction"
    t.string "fi"
    t.string "type_vol"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["avion_id"], name: "index_reservations_on_avion_id"
    t.index ["user_id"], name: "index_reservations_on_user_id"
  end

  create_table "signalements", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "avion_id", null: false
    t.text "description", null: false
    t.string "status", default: "Ouvert", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["avion_id"], name: "index_signalements_on_avion_id"
    t.index ["user_id"], name: "index_signalements_on_user_id"
  end

  create_table "tarifs", force: :cascade do |t|
    t.integer "annee"
    t.integer "tarif_horaire_avion1"
    t.integer "tarif_horaire_avion2"
    t.integer "tarif_instructeur"
    t.integer "tarif_simulateur"
    t.integer "cotisation_club_m21"
    t.integer "cotisation_club_p21"
    t.integer "cotisation_autre_ffa"
    t.integer "licence_ffa"
    t.integer "licence_ffa_info_pilote"
    t.integer "elearning_theorique"
    t.integer "pack_pilote_m21"
    t.integer "pack_pilote_p21"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "user_id"
    t.date "date_transaction"
    t.string "description"
    t.string "mouvement"
    t.decimal "montant", precision: 8, scale: 2
    t.string "piece_justificative"
    t.string "payment_method"
    t.boolean "is_checked"
    t.string "source_transaction"
    t.string "attachment_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "prenom"
    t.string "nom"
    t.date "date_naissance"
    t.string "lieu_naissance"
    t.string "profession"
    t.string "adresse"
    t.string "telephone"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "contact_urgence"
    t.string "num_ffa"
    t.string "licence_type"
    t.string "num_licence"
    t.date "date_licence"
    t.string "type_medical"
    t.date "medical"
    t.date "nuit"
    t.date "fi"
    t.date "fe"
    t.date "controle"
    t.decimal "solde", precision: 8, scale: 2, default: "0.0", null: false
    t.date "cotisation_club"
    t.date "cotisation_ffa"
    t.boolean "autorise"
    t.boolean "admin", default: false, null: false
    t.string "fonction"
    t.string "google_access_token"
    t.string "google_refresh_token"
    t.datetime "google_token_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vols", force: :cascade do |t|
    t.integer "user_id"
    t.integer "avion_id"
    t.integer "instructeur_id"
    t.string "type_vol", default: "Standard", null: false
    t.string "depart", null: false
    t.string "arrivee", null: false
    t.datetime "debut_vol", null: false
    t.datetime "fin_vol", null: false
    t.float "compteur_depart", null: false
    t.float "compteur_arrivee", null: false
    t.float "duree_vol", null: false
    t.integer "nb_atterro", default: 1, null: false
    t.boolean "solo", default: false, null: false
    t.boolean "supervise", default: false, null: false
    t.boolean "nav", default: false, null: false
    t.string "nature", default: "VFR de jour", null: false
    t.float "fuel_avant_vol", default: 0.0, null: false
    t.float "fuel_apres_vol", default: 0.0, null: false
    t.float "huile", default: 0.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["avion_id"], name: "index_vols_on_avion_id"
    t.index ["instructeur_id"], name: "index_vols_on_instructeur_id"
    t.index ["user_id"], name: "index_vols_on_user_id"
  end

  create_table "web_push_subscriptions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "endpoint"
    t.string "p256dh"
    t.string "auth"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_web_push_subscriptions_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attendances", "events"
  add_foreign_key "attendances", "users"
  add_foreign_key "events", "users", column: "admin_id"
  add_foreign_key "reservations", "avions"
  add_foreign_key "reservations", "users"
  add_foreign_key "signalements", "avions"
  add_foreign_key "signalements", "users"
  add_foreign_key "transactions", "users"
  add_foreign_key "vols", "avions"
  add_foreign_key "vols", "users"
  add_foreign_key "vols", "users", column: "instructeur_id"
  add_foreign_key "web_push_subscriptions", "users"
end
