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

ActiveRecord::Schema[8.0].define(version: 2025_12_15_120559) do
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

  create_table "activity_logs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "action"
    t.string "record_type"
    t.integer "record_id"
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
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

  create_table "comments", force: :cascade do |t|
    t.integer "user_id"
    t.integer "event_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_comments_on_event_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
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
    t.string "google_event_id"
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

  create_table "immobs", force: :cascade do |t|
    t.string "description"
    t.date "date_acquisition"
    t.decimal "valeur_acquisition", precision: 10, scale: 2
    t.integer "duree_amortissement"
    t.integer "purchase_transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["purchase_transaction_id"], name: "index_immobs_on_purchase_transaction_id"
  end

  create_table "instructor_availabilities", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "day", null: false
    t.string "period", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "day", "period"], name: "index_instructor_availabilities_on_user_id_and_day_and_period", unique: true
    t.index ["user_id"], name: "index_instructor_availabilities_on_user_id"
  end

  create_table "livrets", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_id"
    t.integer "flight_lesson_id"
    t.string "title"
    t.integer "status", default: 0
    t.date "date"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_livrets_on_course_id"
    t.index ["flight_lesson_id"], name: "index_livrets_on_flight_lesson_id"
    t.index ["user_id"], name: "index_livrets_on_user_id"
  end

  create_table "news_items", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_news_items_on_user_id"
  end

  create_table "penalites", force: :cascade do |t|
    t.integer "user_id"
    t.string "avion_immatriculation"
    t.datetime "reservation_start_time"
    t.datetime "reservation_end_time"
    t.string "instructor_name"
    t.text "cancellation_reason"
    t.decimal "penalty_amount", precision: 8, scale: 2
    t.string "status", default: "En attente"
    t.integer "admin_id"
    t.text "admin_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_penalites_on_admin_id"
    t.index ["user_id"], name: "index_penalites_on_user_id"
  end

  create_table "questions", force: :cascade do |t|
    t.text "qcm"
    t.string "answer_1"
    t.string "answer_2"
    t.string "answer_3"
    t.string "answer_4"
    t.integer "correct_answer"
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_questions_on_course_id"
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
    t.string "google_instructor_event_id"
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

  create_table "settings", force: :cascade do |t|
    t.string "var", null: false
    t.text "val"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["var"], name: "index_settings_on_var", unique: true
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
    t.integer "tarif_horaire_avion3"
    t.integer "tarif_horaire_avion4"
    t.integer "tarif_horaire_avion5"
    t.integer "tarif_horaire_avion6"
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
    t.datetime "deleted_at"
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
    t.date "date_fin_formation"
    t.string "google_calendar_id"
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
    t.integer "livret_id"
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
    t.index ["livret_id"], name: "index_vols_on_livret_id"
    t.index ["user_id"], name: "index_vols_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_logs", "users"
  add_foreign_key "attendances", "events"
  add_foreign_key "attendances", "users"
  add_foreign_key "comments", "events"
  add_foreign_key "comments", "users"
  add_foreign_key "events", "users", column: "admin_id"
  add_foreign_key "immobs", "transactions", column: "purchase_transaction_id"
  add_foreign_key "instructor_availabilities", "users"
  add_foreign_key "livrets", "courses"
  add_foreign_key "livrets", "flight_lessons"
  add_foreign_key "livrets", "users"
  add_foreign_key "news_items", "users"
  add_foreign_key "penalites", "users"
  add_foreign_key "penalites", "users", column: "admin_id"
  add_foreign_key "questions", "courses"
  add_foreign_key "reservations", "avions"
  add_foreign_key "reservations", "users"
  add_foreign_key "signalements", "avions"
  add_foreign_key "signalements", "users"
  add_foreign_key "transactions", "users"
  add_foreign_key "vols", "avions"
  add_foreign_key "vols", "livrets"
  add_foreign_key "vols", "users"
  add_foreign_key "vols", "users", column: "instructeur_id"
end
