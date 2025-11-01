# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command.

require 'faker'

puts "\nCleaning database..."
Transaction.destroy_all
Audio.destroy_all
FlightLesson.destroy_all
Reservation.destroy_all
Vol.destroy_all
Avion.destroy_all
Tarif.destroy_all
Attendance.destroy_all
Event.destroy_all # Doit être détruit après Attendance
User.destroy_all # Doit être détruit en dernier car beaucoup de tables en dépendent
Course.destroy_all
puts "✅ Cleaned"

puts "Réinitialisation des IDs de séquence pour SQLite..."
ActiveRecord::Base.connection.tables.each do |t|
  ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name = '#{t}'")
end
puts "✅ Cleaned"

puts "\nCreating users..."

# On désactive temporairement l'envoi d'e-mails pour éviter les erreurs de letter_opener
original_delivery_method = ActionMailer::Base.delivery_method
ActionMailer::Base.delivery_method = :test

# 1. Création de 30 adhérents, dont un administrateur et un élève
# ---------------------------------------------------------------

# Crée un administrateur
admin_user = User.create!(
  prenom: "Admin",
  nom: "User",
  email: "admin@bastair.com",
  password: "password",
  password_confirmation: "password",
  admin: true,
  date_naissance: Faker::Date.birthday(min_age: 61, max_age: 65),
  lieu_naissance: Faker::Address.city,
  profession: "Administrateur Système",
  adresse: Faker::Address.full_address,
  telephone: Faker::PhoneNumber.phone_number,
  contact_urgence: "#{Faker::Name.name} - #{Faker::PhoneNumber.phone_number}",
  num_ffa: Faker::Number.number(digits: 8).to_s,
  licence_type: "PPL",
  num_licence: "FRA.PPL.#{Faker::Number.number(digits: 6)}",
  date_licence: Faker::Date.backward(days: 365 * 5),
  medical: Faker::Date.forward(days: 365),
  fi: Faker::Date.forward(days: 365),
  fe: Faker::Date.forward(days: 365),
  controle: Faker::Date.forward(days: 365),
  solde: Faker::Number.decimal(l_digits: 3, r_digits: 2),
  cotisation_club: Faker::Date.forward(days: 365),
  cotisation_ffa: Faker::Date.forward(days: 365),
  autorise: true,
  fonction: "president"
)
puts "✅ Administrator created: #{admin_user.email}"

# Crée un élève
eleve_user = User.create!(
  prenom: "Eleve",
  nom: "Debutant",
  email: "eleve@bastair.com",
  password: "password",
  password_confirmation: "password",
  admin: false,
  date_naissance: Faker::Date.birthday(min_age: 61, max_age: 65),
  lieu_naissance: Faker::Address.city,
  profession: "Administrateur Système",
  adresse: Faker::Address.full_address,
  telephone: Faker::PhoneNumber.phone_number,
  contact_urgence: "#{Faker::Name.name} - #{Faker::PhoneNumber.phone_number}",
  num_ffa: Faker::Number.number(digits: 8).to_s,
  licence_type: "PPL",
  num_licence: "FRA.PPL.#{Faker::Number.number(digits: 6)}",
  date_licence: Faker::Date.backward(days: 365 * 5),
  medical: Faker::Date.forward(days: 365),
  fi: Faker::Date.forward(days: 365),
  fe: Faker::Date.forward(days: 365),
  controle: Faker::Date.forward(days: 365),
  solde: Faker::Number.decimal(l_digits: 3, r_digits: 2),
  cotisation_club: Faker::Date.forward(days: 365),
  cotisation_ffa: Faker::Date.forward(days: 365),
  autorise: true,
  fonction: "eleve"
)
puts "✅ Trainee created: #{eleve_user.email}"

# Crée 28 adhérents normaux (non élève)
29.times do
  licence = ["PPL", "LAPL"].sample
  User.create!(
    prenom: Faker::Name.first_name,
    nom: Faker::Name.last_name,
    email: Faker::Internet.unique.email,
    password: "password",
    password_confirmation: "password",
    date_naissance: Faker::Date.birthday(min_age: 17, max_age: 70),
    lieu_naissance: Faker::Address.city,
    profession: Faker::Job.title,
    adresse: Faker::Address.full_address,
    telephone: Faker::PhoneNumber.phone_number,
    contact_urgence: "#{Faker::Name.name} - #{Faker::PhoneNumber.phone_number}",
    num_ffa: Faker::Number.number(digits: 8).to_s,
    licence_type: licence,
    num_licence: "FRA.#{licence}.#{Faker::Number.number(digits: 6)}",
    date_licence: Faker::Date.backward(days: 365 * 10),
    medical: Faker::Date.forward(days: 365),
    controle: Faker::Date.forward(days: 365),
    solde: Faker::Number.decimal(l_digits: 2, r_digits: 2),
    cotisation_club: Faker::Date.forward(days: 365),
    cotisation_ffa: Faker::Date.forward(days: 365),
    autorise: [true, true, true, false].sample, # 75% de chance d'être autorisé
    admin: false,
    fonction: "brevete"
    )
end
puts "✅ 28 regular members created."
puts "Total users: #{User.count}"

# On réactive l'envoi d'e-mails
ActionMailer::Base.delivery_method = original_delivery_method


# 2. Création d'un avion
# ----------------------------------------------------

puts "\nCreating aircraft..."
avion = Avion.create!(
  immatriculation: "F-HGBT",
  marque: "Bristell",
  modele: "B23",
  conso_horaire: 18,
  certif_immat: Faker::Date.forward(days: 365),
  cert_navigabilite: Faker::Date.forward(days: 365),
  cert_examen_navigabilite: Faker::Date.forward(days: 365),
  licence_station_aeronef: Faker::Date.forward(days: 365),
  cert_limitation_nuisances: Faker::Date.forward(days: 365),
  fiche_pesee: Faker::Date.forward(days: 365),
  assurance: Faker::Date.forward(days: 365),
  _50h: Faker::Date.forward(days: 30),
  _100h: Faker::Date.forward(days: 60),
  annuelle: Faker::Date.forward(days: 365),
  gv: Faker::Date.forward(days: 1095),
  helice: Faker::Date.forward(days: 1095),
  parachute: Faker::Date.forward(days: 1095),
  potentiel_cellule: 5000.00,
  potentiel_moteur: 2000.00
)
puts "✅ Aircraft created: #{avion.immatriculation}"


# 3. Création de 20 vols
# ----------------------------------------------------

puts "\nCreating flights..."
aerodromes = ["TFFB", "TFFS", "TFFM", "TFFR", "TFFC", "TFFA"]
types_vol = ["solo", "instruction", "contrôle FI", "vol découverte", "vol d'initiation", "vol d'essai", "convoyage", "vol BIA"]
all_users = User.all
compteur_actuel = 1234.5

20.times do
  depart_time = Faker::Time.between(from: DateTime.now - 30, to: DateTime.now + 30)
  duree_minutes = [30, 45, 60, 90, 120].sample
  duree_heures = duree_minutes / 60.0
  Vol.create!(
    user: all_users.sample, # Correctly assign a random user
    avion: avion,           # Assign the created aircraft
    type_vol: types_vol.sample,
    depart: aerodromes.sample,
    arrivee: aerodromes.sample,
    debut_vol: depart_time,
    fin_vol: depart_time + duree_minutes.minutes,
    compteur_depart: compteur_actuel,
    compteur_arrivee: compteur_actuel + duree_minutes,
    duree_vol: duree_minutes,
    nb_atterro: [1, 2, 3].sample,
    solo: [true, false].sample,
    supervise: [true, false].sample,
    nav: [true, false].sample,
    jour: true,
    fuel_avant_vol: Faker::Number.between(from: 80.0, to: 100.0).round(1),
    fuel_apres_vol: Faker::Number.between(from: 40.0, to: 60.0).round(1),
    huile: Faker::Number.between(from: 2.0, to: 3.0).round(1)
  )
  compteur_actuel += duree_minutes + 15 # Ajoute un petit temps au sol entre 2 vols
end
puts "✅ 20 flights created."


# 4. Création de 20 réservations
# ----------------------------------------------------

puts "\nCreating bookings..."
20.times do
  date_vol = Faker::Time.between(from: DateTime.now + 30, to: DateTime.now + 3000)
  Reservation.create!(
    user: all_users.sample, # Correctly assign a random user
    avion: avion,           # Assign the created aircraft
    date_debut: date_vol,
    date_fin: date_vol + 60.minutes,
    instruction: [true, false].sample,
    fi: "Toto",
    type_vol: types_vol.sample
  )
end
puts "✅ 20 bookings created."


puts "\nCreating 10 events..."
10.times do
  event = Event.create!(
    title: Event::ALLOWED_TITLES.sample, # titre parmi les titres autorisés
    description: Faker::Lorem.paragraph(sentence_count: 5),
    start_date: Faker::Time.forward(days: 30, period: :day),
    price: 0,
    admin: admin_user # On associe l'événement à l'administrateur créé plus haut
  )
  puts "Created event: #{event.title}"
end
puts "✅ 10 events created."


# 5. Création des tarifs annuels
# ----------------------------------------------------
puts "\nCreating annual rates..."
Tarif.create!(
  annee: Date.today.year,
  tarif_horaire_avion1: 150,
  tarif_horaire_avion2: 0,    # Mettre à jour si autres avions (faire une migration)
  tarif_instructeur: 10,
  tarif_simulateur: 20,
  cotisation_club_m21: 100,
  cotisation_club_p21: 200,
  cotisation_autre_ffa: 100,
  licence_ffa: 92,
  licence_ffa_info_pilote: 141,
  elearning_theorique: 70,
  pack_pilote_m21: 0,         # Offert
  pack_pilote_p21: 75
)
puts "✅ Annual rates for #{Date.today.year} created."


# 6. Création des cours théoriques
# ----------------------------------------------------
puts "\nCreating Courses..."

# Assurez-vous d'avoir un fichier d'exemple dans app/assets/files/sample.pdf
sample_pdf_path = Rails.root.join('app', 'assets', 'files', 'sample.pdf')

courses_data = [
  { title: "FTP1 Environnement réglementaire de la formation", description: "Eléments du PART NCO, SGS (ATO) ou politique de sécurité (DTO), Retour d’expérience REX FFA et occurrence reporting dans le cadre du règlement 376/2014, Manuel de sécurité FA..", file: "ftp1.pdf" },
  { title: "FTP2 Mise en œuvre de l’avion. Eléments de sécurité élémentaire", description: "Eléments de sécurité élémentaire. Préparation pour le vol (les 5 éléments de contexte). Actions avant et après vol (objectifs du briefing et débriefing). Compétences techniques/Non techniques.", file: "ftp2.pdf" },
  { title: "FTP3 Bases d’aérodynamique (assiette – incidence – pente)", description: "Puissance nécessaire au vol. Relation puissance/assiette/vitesse/trajectoire.", file: "ftp3.pdf" },
  { title: "FTP4 Signaux de guidage au sol. Procédures de contrôle de la circulation aérienne", description: "Procédures de contrôle de la circulation aérienne. Urgences : Pannes de freins et de direction. Virages : Notions de facteur de charge et puissance requise. Contrôle du cap : Utilisation du compas et du conservateur de cap. ffets du vent : Notion de dérive.", file: "ftp4.pdf" },
  { title: "FTP5 Mécanique du vol et vitesses caractéristiques (évolution – V réf…)", description: "Limitations avion et dangers associés. Circonstances menant aux situations inusuelles, détection et récupération.", file: "ftp5.pdf" },
  { title: "FTP6 Le tour de piste – communication", description: "Approche gestion menaces et erreurs (Menaces, erreurs et situations indésirables) dans le cadre des vols locaux.", file: "fpt6.pdf" },
  { title: "FTP7 Pannes et procédures particulières : Identifier, analyser, appliquer une procédure", description: "Situations d’urgence. Appliquer une procédure d’urgence.", file: "ftp7.pdf" },
  { title: "FTP8 Méthodes de navigation. Préparation d’une navigation (journal de navigation)", description: "Rappels réglementation : Espaces aérien, conditions VMC, altitudes et niveaux de vol, services ATC, intégration sur les aérodromes", file: "ftp8.pdf" },
  { title: "FTP9 Présentation des moyens de radionavigations conventionnels et du GPS", description: "Utilisation et organisation des moyens radio. Approche gestion des menaces et erreurs (Menaces, erreurs, et situations indésirables) dans le cadre du vol sur la campagne.", file: "ftp9.pdf" },
  { title: "FTP10 Présentation du dossier de vol", description: "Préparation d’un voyage aérien (avitaillement, assistance). Approche gestion menaces et erreurs (Menaces, erreurs et situations indésirables) dans le cadre du voyage avec passagers. Gestion des pannes et situations anormales. Déroutement. Interruption volontaire du vol.", file: "ftp10.pdf" },
  { title: "FTP11 Pilotage sans visibilité", description: "(VSV, circuit visuel). Approche gestion menaces et erreurs (Menaces, erreurs, situations indésirables) dans le cadre du VSV. Maintien des conditions VMC, réactions en cas de perte de conditions VMC, retour aux conditions VMC.", file: "ftp11.pdf" },
  { title: "FTP12 Présentation de l’examen", description: "Présentation de l’examenau travers du guide FFA de l’examen en vol et du manuel de sécurité FFA ; Détail des exercices et de leur enchaînement, critères observés, niveau attendu, contenu du briefing.", file: "ftp12.pdf" },
  { title: "Facteurs Humains", description: "Cours sur les facteurs humains", file: "facteurs_humains.pdf" }
]

courses_data.each do |course_data|
  course = Course.create!(title: course_data[:title], description: course_data[:description])
  # Attache le fichier PDF via Active Storage
  file_path = Rails.root.join('app', 'assets', 'files', course_data[:file])
  if File.exist?(file_path)
    course.document.attach(io: File.open(file_path), filename: course_data[:file], content_type: 'application/pdf')
  else
    puts "      ⚠️  Warning: File #{course_data[:file]} not found for course '#{course_data[:title]}'."
  end
end
puts "✅ Courses created."


# 7. Création des podcasts
# ----------------------------------------------------
puts "\nCreating Podcasts..."
Audio.destroy_all

podcasts_data = [
  { title: "Voler par fortes chaleurs", description: "Les questions à se poser quand il fait chaud. Attention les performances de l'avion sont dégradées.", file: "HighTemperatureFlightOperations.wav" },
  { title: "Les virages", description: "Des explications sur les bonnes pratiques pour effectuer un virage parfait.", file: "AerialManeuversTurnsSymmetry.wav" },
  { title: "Le SIV", description: "Le Service D'Information de Vol (SIV), c'est quoi ?", file: "FlightInformationService.wav" },
  { title: "Préparer une navigation VFR", description: "Un podcast qui explique la préparation d'une navigation VFR.", file: "PracticalGuideVFRNavigation.wav" },
  { title: "SIV et espaces aériens", description: "Les espaces aériens et le SIV.", file: "VFRAirspace.wav" }
  # autres podcasts : ajouter ici
]

podcasts_data.each do |podcast_data|
  audio = Audio.create!(title: podcast_data[:title], description: podcast_data[:description])
  podcast_file_path = Rails.root.join('app', 'assets', 'files', podcast_data[:file])
  if File.exist?(podcast_file_path)
    audio.audio.attach(io: File.open(podcast_file_path), filename: podcast_data[:file], content_type: 'audio/mpeg')
  end
end
puts "✅ #{Audio.count} podcast(s) created."

# 8. Création des leçons de vol
# ----------------------------------------------------
puts "\nCreating Flight Lessons..."

flight_lessons_data = [
  { title: "1 Mise en œuvre, roulage et vol d’accoutumance", file: "lecon_1.pdf" },
  { title: "2 Assiette, inclinaison et ligne droite", file: "lecon_2.pdf" },
  { title: "3 Utilisation du moteur et du compensateur", file: "lecon_3.pdf" },
  { title: "4 Alignement et décollage", file: "lecon_4.pdf" },
  { title: "5 Assiette - Vitesse assiette - Trajectoire", file: "lecon_5.pdf" },
  { title: "6 Relation puissance vitesse - Incidence", file: "lecon_6.pdf" },
  { title: "7 Contrôle du cap", file: "lecon_7.pdf" },
  { title: "8 Palier, montée et descente symétrie du vol", file: "lecon_8.pdf" },
  { title: "9 Virages en palier, montée et descente symétrie du vol", file: "lecon_9.pdf" },
  { title: "10 Relations dans le virage", file: "lecon_10.pdf" },
  { title: "11 Effets du vent traversier sur les trajectoires sol", file: "lecon_11.pdf" },
  { title: "12 Changement de configuration", file: "lecon_12.pdf" },
  { title: "13 Décrochage", file: "lecon_13.pdf" },
  { title: "14 Vol lent", file: "lecon_14.pdf" },
  { title: "15 Chargement, centrage et stabilité longitudinale", file: "lecon_15.pdf" },
  { title: "16 Approche et approche interrompue", file: "lecon_16.pdf" },
  { title: "17 L’atterrissage", file: "lecon_17.pdf" },
  { title: "18 Circuits d’aérodrome", file: "lecon_18.pdf" },
  { title: "19 Virage engagé", file: "lecon_19.pdf" },
  { title: "20 Pannes en phase de décollage", file: "lecon_20.pdf" },
  { title: "21 Virage à grande inclinaison", file: "lecon_21.pdf" },
  { title: "22 Le lâcher", file: "lecon_22.pdf" },
  { title: "23 Décollages et montées adaptés", file: "lecon_23.pdf" },
  { title: "24 Approches et atterrissages adaptés", file: "lecon_24.pdf" },
  { title: "25 Atterrissage de précaution", file: "lecon_25.pdf" },
  { title: "26 Le vol moteur réduit", file: "lecon_26.pdf" },
  { title: "27 La vrille", file: "lecon_27.pdf" },
  { title: "28 Procédures anormales et d’urgence", file: "lecon_28.pdf" },
  { title: "29 Virage à forte inclinaison en descente moteur réduit", file: "lecon_29.pdf" },
  { title: "30 L’estime élémentaire", file: "lecon_30.pdf" },
  { title: "31 Le cheminement", file: "lecon_31.pdf" },
  { title: "32 Navigation", file: "lecon_32.pdf" },
  { title: "33 Application au voyage", file: "lecon_33.pdf" },
  { title: "34 Radionavigation", file: "lecon_34.pdf" },
  { title: "35 Egarement", file: "lecon_35.pdf" },
  { title: "36 Perte de références extérieures", file: "lecon_36.pdf" },
  { title: "37 Utilisation du GPS", file: "lecon_37.pdf" }
]

flight_lessons_data.each do |lesson_data|
  lesson = FlightLesson.create!(title: lesson_data[:title].split(' ', 2).last)
  # Vous pouvez placer vos PDFs dans 'app/assets/files/flight_lessons/'
  file_path = Rails.root.join('app', 'assets', 'files', 'flight_lessons', lesson_data[:file])
  if File.exist?(file_path)
    lesson.document.attach(io: File.open(file_path), filename: lesson_data[:file], content_type: 'application/pdf')
  else
    puts "      ⚠️  Warning: File #{lesson_data[:file]} not found for flight lesson '#{lesson.title}'."
  end
end
puts "✅ Flight Lessons created."


# 9. Création de 20 transactions
# ----------------------------------------------------
puts "\nCreating 20 transactions..."

payment_methods = ['Carte bancaire', 'Virement', 'Chèque', 'Espèces']
descriptions_recette = ["Crédit compte", "Achat bloc 6h", "Paiement cotisation annuelle", "Participation événement BBQ"]
descriptions_depense = ["Heure de vol F-HGBT", "Achat casque", "Taxe atterrissage", "Remboursement"]

20.times do
  mouvement = ['Recette', 'Dépense'].sample
  description = mouvement == 'Recette' ? descriptions_recette.sample : descriptions_depense.sample
  
  Transaction.create!(
    user: all_users.sample,
    date_transaction: Faker::Date.between(from: 1.year.ago, to: Date.today),
    description: description,
    mouvement: mouvement,
    montant: Faker::Commerce.price(range: 10..500),
    payment_method: payment_methods.sample,
    is_checked: [true, false].sample,
    source_transaction: Transaction::ALLOWED_TSN.values.sample
  )
end
puts "✅ 20 transactions created."

puts "\nSeed finished successfully!"
puts
