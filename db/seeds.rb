# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command.

require 'faker'

if Rails.env.production?
  puts "Le script de seed est désactivé en environnement de production pour éviter toute perte de données."
  puts "Si vous souhaitez ajouter des données en production, il faut le faire manuellement (via la gestion des BDD)."
  exit
end

puts "\n--- Gestion des Agendas Google ---"
print "Voulez-vous effacer les rendez-vous des agendas ? (o/N) "
response = STDIN.gets.chomp.downcase

if response == 'o'
  puts "Effacement des événements des agendas Google en cours..."
  begin
    service = GoogleCalendarService.new
    calendar_ids = [
      ENV['GOOGLE_CALENDAR_ID_EVENTS'],
      ENV['GOOGLE_CALENDAR_ID_AVION_F_HGBT'],
      ENV['GOOGLE_CALENDAR_ID_INSTRUCTEUR_HUY']
    ].compact.uniq

    if calendar_ids.empty?
      puts "⚠️  Aucun ID de calendrier Google trouvé dans les variables d'environnement."
    else
      calendar_ids.each do |cal_id|
        puts "\nTraitement de l'agenda : #{cal_id}"
        service.clear_calendar(cal_id)
      end
      puts "✅ Tous les événements ont été effacés des agendas."
    end
  rescue => e
    puts "❌ Erreur lors de la communication avec l'API Google Calendar : #{e.message}"
    puts "Veuillez vérifier vos credentials et la configuration de l'API."
  end
end

puts "\nCleaning database..."
# On détruit les tables dépendantes en premier
Transaction.destroy_all
Comment.destroy_all
NewsItem.destroy_all
Signalement.destroy_all
Audio.destroy_all
FlightLesson.destroy_all
Reservation.destroy_all
Vol.destroy_all
Avion.destroy_all
Tarif.destroy_all
Attendance.destroy_all # Dépend de User et Event
Event.destroy_all # Dépend de User (admin)
User.destroy_all # Doit être détruit après toutes les tables qui ont un user_id
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
  telephone: '0606060606',
  contact_urgence: "#{Faker::Name.name} - #{Faker::PhoneNumber.phone_number}",
  num_ffa: Faker::Number.number(digits: 7).to_s,
  licence_type: "ATPL",
  num_licence: Faker::Number.number(digits: 8).to_s,
  date_licence: "2026-12-31",
  medical: Faker::Date.forward(days: 365),
  fi: Faker::Date.forward(days: 365),
  fe: Faker::Date.forward(days: 365),
  controle: Faker::Date.forward(days: 365),
  solde: 0.0, # On initialise le solde à 0
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
  telephone: '0606060606',
  contact_urgence: "#{Faker::Name.name} - #{Faker::PhoneNumber.phone_number}",
  num_ffa: Faker::Number.number(digits: 7).to_s,
  licence_type: "PPL",
  num_licence: nil,
  date_licence: nil,
  medical: Faker::Date.forward(days: 365),
  fi: nil,
  fe: nil,
  controle: Faker::Date.forward(days: 365),
  solde: 0.0, # On initialise le solde à 0
  cotisation_club: Faker::Date.forward(days: 365),
  cotisation_ffa: Faker::Date.forward(days: 365),
  autorise: true,
  fonction: "eleve"
)
puts "✅ Trainee created: #{eleve_user.email}"

# Crée un instructeur
instructeur_user = User.create!(
  prenom: "Christian",
  nom: "HUY",
  email: "instructeur@bastair.com",
  password: "password",
  password_confirmation: "password",
  admin: false,
  date_naissance: Faker::Date.birthday(min_age: 40, max_age: 60),
  lieu_naissance: Faker::Address.city,
  profession: "Pilote de ligne",
  adresse: Faker::Address.full_address,
  telephone: '0607070707',
  contact_urgence: "#{Faker::Name.name} - #{Faker::PhoneNumber.phone_number}",
  num_ffa: Faker::Number.number(digits: 7).to_s,
  licence_type: "CPL",
  num_licence: Faker::Number.number(digits: 8).to_s,
  date_licence: Faker::Date.backward(days: 365),
  medical: Faker::Date.forward(days: 365),
  fi: Faker::Date.forward(days: 730), # Date FI valide pour 2 ans (c'est la présence d'une date valide qui donne le statut d'instructeur)
  fe: nil,
  controle: Faker::Date.forward(days: 365),
  solde: 0.0, # On initialise le solde à 0
  cotisation_club: Faker::Date.forward(days: 365),
  cotisation_ffa: Faker::Date.forward(days: 365),
  autorise: true,
  fonction: "tresorier"
)
puts "✅ Instructor created: #{instructeur_user.email}"

# Crée 27 adhérents normaux (non élève)
puts "\nCreating 27 regular members..."
27.times do
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
    telephone: '0606060606',
    contact_urgence: "#{Faker::Name.name} - #{Faker::PhoneNumber.phone_number}",
    num_ffa: Faker::Number.number(digits: 7).to_s,
    licence_type: licence,
    num_licence: Faker::Number.number(digits: 8).to_s,
    date_licence: Faker::Date.backward(days: 365 * 10),
    medical: Faker::Date.forward(days: 365),
    fi: nil,
    fe: nil,
    controle: Faker::Date.forward(days: 365),
    solde: 0.0, # On initialise le solde à 0
    cotisation_club: Faker::Date.forward(days: 365),
    cotisation_ffa: Faker::Date.forward(days: 365),
    autorise: [true, true, true, false].sample, # 75% de chance d'être autorisé
    admin: false,
    fonction: "brevete"
    )
    print "*" # barre de progression
  end
puts "\n✅ 27 regular members created."
puts "Total users: #{User.count}"

# Création de la transaction initiale de 1000€ pour chaque utilisateur
puts "\nCreating initial 1000€ transaction for each user..."
User.find_each do |user|
  Transaction.create!(
    user: user,
    date_transaction: user.created_at.to_date,
    description: "Crédit initial du compte",
    mouvement: 'Recette',
    montant: 1000.0,
    source_transaction: 'Cotisations des Membres', # Mis à jour pour correspondre aux nouvelles catégories
    payment_method: 'Virement',
    is_checked: true
  )
end
puts "✅ Initial transactions created."


# 2. Création d'un avion / achat
# ----------------------------------------------------
puts "\nCreating aircraft..."
avion = Avion.create!(
  immatriculation: "F-HGBT",
  marque: "Elixir Aircraft",
  modele: "Exlixir",
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
# Création de la transaction d'achat de l'avion et de l'immobilisation correspondante
puts "\nCreating aircraft purchase transaction and immobilization..."
purchase_date = 2.years.ago.to_date
aircraft_purchase_transaction = Transaction.create!(
  date_transaction: purchase_date,
  description: "Achat avion Elixir F-HGBT",
  mouvement: 'Dépense',
  montant: 300000.0,
  source_transaction: 'Charges Exceptionnelles', # Remplacé par une catégorie valide
  payment_method: 'Virement',
  is_checked: true
)
Immobilisation.create!(
  description: "Avion Elixir F-HGBT",
  date_acquisition: purchase_date,
  valeur_acquisition: 300000.0,
  duree_amortissement: 7, # en années
  purchase_transaction: aircraft_purchase_transaction
)
puts "✅ Aircraft immobilization created."

# 3. Création des tarifs annuels
# ----------------------------------------------------
# On crée les tarifs AVANT les vols pour pouvoir calculer leur coût.
puts "\nCreating annual rates..."
Tarif.create!(
  annee: Date.today.year,
  tarif_horaire_avion1: 150,
  tarif_horaire_avion2: 0,
  tarif_horaire_avion3: 0,
  tarif_horaire_avion4: 0,
  tarif_horaire_avion5: 0,
  tarif_horaire_avion6: 0,    # Mettre à jour si autres avions (faire un rollback puis une migration)
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


# 3. Création de 20 vols
# ----------------------------------------------------
puts "\nCreating 20 flights..."
aerodromes = ["TFFB", "TFFS", "TFFM", "TFFR", "TFFC", "TFFA"]
types_vol = ["Standard", "Vol découverte", "Vol d'initiation", "Vol d'essai", "Convoyage", "Vol BIA"]

# On sépare les élèves des autres pour la logique de création des vols
eleve_users = User.where(fonction: 'eleve')
other_users = User.where.not(fonction: 'eleve')
all_users = eleve_users + other_users # On garde une liste complète si besoin

# On récupère l'instructeur créé plus haut
instructeur = User.find_by(email: 'instructeur@bastair.com')

compteur_actuel = 123.45

20.times do
  depart_time = Faker::Time.between(from: 30.days.ago, to: DateTime.now)
  
  # On choisit un utilisateur au hasard AVANT de créer le vol
  pilote = all_users.sample

  # Génère une durée de vol aléatoire entre 0.55 et 3.05 (centièmes d'heure)
  duree_vol_aleatoire = Faker::Number.between(from: 0.55, to: 3.05).round(2)
  
  vol = Vol.new(
    user: pilote,
    avion: avion,
    type_vol: types_vol.sample,
    depart: aerodromes.sample,
    arrivee: aerodromes.sample,
    debut_vol: depart_time,
    fin_vol: depart_time + (duree_vol_aleatoire * 60).minutes,
    compteur_depart: compteur_actuel.round(2),
    compteur_arrivee: (compteur_actuel + duree_vol_aleatoire).round(2),
    duree_vol: duree_vol_aleatoire,
    instructeur_id: pilote.eleve? ? instructeur.id : nil,
    nb_atterro: [1, 2, 3].sample,
    solo: [true, false].sample,
    supervise: [true, false].sample,
    nav: [true, false].sample,
    nature: 'VFR de jour',
    fuel_avant_vol: Faker::Number.between(from: 10.0, to: 100.0).round(1),
    fuel_apres_vol: Faker::Number.between(from: 20.0, to: 110.0).round(1),
    huile: Faker::Number.between(from: 2.0, to: 3.0).round(1)
  )

  if vol.save
    # Calcul du coût du vol
    tarif = Tarif.order(annee: :desc).first
    cost = vol.duree_vol * tarif.tarif_horaire_avion1
    if vol.instructeur_id.present? && !vol.solo?
      cost += vol.duree_vol * tarif.tarif_instructeur
    end

    # Création de la transaction débitant le compte du pilote
    Transaction.create!(
      user: vol.user,
      date_transaction: vol.debut_vol.to_date,
      description: "Vol du #{vol.debut_vol.to_date.strftime('%d/%m/%Y')} sur #{vol.avion.immatriculation}",
      mouvement: 'Dépense',
      montant: cost.round(2),
      source_transaction: 'Heures de Vol / Location Avions', # Remplacé par une catégorie valide
      payment_method: 'Prélèvement sur compte',
      is_checked: false # à vérifier
    )

    compteur_actuel = (compteur_actuel + 1.90).round(2)  # ajoute un petit temps au sol entre 2 vols
  else
    puts "Error creating flight: #{vol.errors.full_messages.join(', ')}"
  end
  print "*" # barre de progression
end
puts "\n✅ 20 flights created."


# 4. Création de 20 réservations
# ----------------------------------------------------
puts "\nCreating bookings..."
20.times do
  # On génère une date de début dans le futur, avec une heure de début entre 7h et 15h.
  random_day = Faker::Date.between(from: 1.day.from_now, to: 60.days.from_now)
  random_hour = rand(7..15) # Génère une heure entre 7 et 15 inclus
  random_minute = [0, 15, 30, 45].sample # Pour des heures de début plus réalistes
  date_debut = random_day.to_datetime.change(hour: random_hour, min: random_minute)
  
  # On crée l'objet réservation sans le sauvegarder tout de suite
  reservation = Reservation.new(
    user: all_users.sample, # Correctly assign a random user
    avion: avion,           # Assign the created aircraft
    start_time: date_debut,
    end_time: date_debut + 1.hour, # La réservation dure 1 heure
    instruction: [true, false].sample,
    fi: instructeur.id.to_s, # On utilise l'ID de l'instructeur
    type_vol: types_vol.sample
  )

  # On sauvegarde la réservation. Si elle est valide, on crée l'événement Google Calendar.
  if reservation.save
    # On appelle le service pour créer l'événement dans Google Calendar.
    # Le service est conçu pour gérer la création sur l'agenda de l'avion
    # et également sur celui de l'instructeur si `instruction` est à true.
    GoogleCalendarService.new.create_event_for_app(reservation)
  end
end
puts "✅ 20 bookings created."


# 5. Création de 10 events
# ----------------------------------------------------
puts "\nCreating 10 events..."
10.times do
  # On génère une date de début dans le futur, avec une heure de début entre 7h et 15h.
  random_day = Faker::Date.between(from: 1.day.from_now, to: 30.days.from_now)
  random_hour = rand(7..15) # Génère une heure entre 7 et 15 inclus
  random_minute = [0, 15, 30, 45].sample # Pour des heures de début plus réalistes
  date_debut = random_day.to_datetime.change(hour: random_hour, min: random_minute)

  event = Event.new(
    title: Event::ALLOWED_TITLES.sample, # titre parmi les titres autorisés
    description: Faker::Lorem.paragraph(sentence_count: 5),
    start_date: date_debut,
    price: 0,
    admin: admin_user # On associe l'événement à l'administrateur créé plus haut
  )
  if event.save
    # On appelle le service pour créer l'événement dans Google Calendar
    GoogleCalendarService.new.create_event_for_app(event)
    puts "Created event: #{event.title}"
  end
end
puts "✅ 10 events created."


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
    puts "      ⚠️  Warning: File not found : #{course_data[:file]} '#{course_data[:title]}'."
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
    puts "      ⚠️  Warning: File not found : #{lesson_data[:file]} '#{lesson.title}'."
  end
end
puts "✅ Flight Lessons created."


# 9. Création de 20 transactions
# ----------------------------------------------------
puts "\nCreating 20 transactions..."

payment_methods = ['Carte bancaire', 'Virement', 'Chèque', 'Espèces']
descriptions_recette = ["Crédit compte", "Achat bloc 6h", "Paiement cotisation annuelle", "Participation événement BBQ"]
descriptions_depense = ["Heure de vol F-HGBT", "Achat casque", "Taxe atterrissage", "Remboursement", "Achat essence", "Location hangar"]

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
