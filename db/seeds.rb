# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command.

require 'faker'

#--------------------------------------------------- Methods de seed ----------------------------------------------------

def settings
  # initialisation des pénalités
  Setting.find_or_create_by!(var: 'penalty_delay_1', val: '48')
  Setting.find_or_create_by!(var: 'penalty_amount_1', val: '5')
  Setting.find_or_create_by!(var: 'penalty_delay_2', val: '24')
  Setting.find_or_create_by!(var: 'penalty_amount_2', val: '10')
  Setting.find_or_create_by!(var: 'penalty_delay_3', val: '12')
  Setting.find_or_create_by!(var: 'penalty_amount_3', val: '20')
  puts "✅ Paramètres de pénalité créés"
end

def users
  puts "\nCreating users..."

  # 1. Création de 30 adhérents, dont un administrateur et un élève
  # ---------------------------------------------------------------
  # Crée un administrateur
  @admin_user = User.create!(
    prenom: "Admin", # Le nom est changé pour correspondre à la variable d'environnement
    nom: "ADM",
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
    solde: 0.0,
    google_calendar_id: ENV['GOOGLE_CALENDAR_ID_INSTRUCTEUR_ADM'],
    cotisation_club: Faker::Date.forward(days: 365),
    cotisation_ffa: Faker::Date.forward(days: 365),
    autorise: true,
    fonction: "president"
  )
  puts "✅ Administrator created: #{@admin_user.email}"

  # Création des disponibilités pour l'administrateur (tous les jours, matin et après-midi)
  %w[lundi mardi mercredi jeudi vendredi samedi dimanche].each do |day|
    %w[matin apres-midi].each do |period|
      InstructorAvailability.create!(user: @admin_user, day: day, period: period)
    end
  end

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
  @instructeur_user = User.create!(
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
    solde: 0.0,
    google_calendar_id: ENV['GOOGLE_CALENDAR_ID_INSTRUCTEUR_HUY'],
    cotisation_club: Faker::Date.forward(days: 365),
    cotisation_ffa: Faker::Date.forward(days: 365),
    autorise: true,
    fonction: "tresorier"
  )
  puts "✅ Instructor created: #{@instructeur_user.email}"

  # Création des disponibilités pour l'instructeur (tous les jours, matin et après-midi)
  %w[lundi mardi mercredi jeudi vendredi samedi dimanche].each do |day|
    %w[matin apres-midi].each do |period|
      InstructorAvailability.create!(user: @instructeur_user, day: day, period: period)
    end
  end

  # Crée 27 adhérents normaux (non élève)
  puts "\nCreating 27 regular members..."
  # Pour la performance, on prépare les attributs de tous les utilisateurs
  # pour les insérer en une seule requête SQL avec `insert_all`.
  users_attributes = 27.times.map do
    print "*"
    licence = ["PPL", "LAPL"].sample
    # On pré-crypte le mot de passe, car `insert_all` n'exécute pas les callbacks de Devise.
    encrypted_password = User.new(password: "password").encrypted_password
    {
        prenom: Faker::Name.first_name,
        nom: Faker::Name.last_name,
        email: Faker::Internet.unique.email,
        encrypted_password: encrypted_password,
        date_naissance: Faker::Date.birthday(min_age: 17, max_age: 70),
        lieu_naissance: Faker::Address.city,
        profession: Faker::Job.title,
        adresse: Faker::Address.full_address,
        telephone: '0606060606',
        contact_urgence: "#{Faker::Name.name} - #{Faker::PhoneNumber.phone_number}",
        num_ffa: Faker::Number.number(digits: 7).to_s,
        licence_type: licence,
        num_licence: Faker::Number.number(digits: 8).to_s,
        date_licence: Faker::Date.forward(days: 365 * 2),
        medical: Faker::Date.forward(days: 365),
        fi: nil,
        fe: nil,
        controle: Faker::Date.forward(days: 365),
        solde: 0.0,
        cotisation_club: Faker::Date.forward(days: 365),
        cotisation_ffa: Faker::Date.forward(days: 365),
        autorise: [true, true, true, false].sample,
        admin: false,
        fonction: "brevete",
        created_at: Time.current,
        updated_at: Time.current
    }
  end
  User.insert_all(users_attributes)
  puts "\n✅ 27 regular members created."
  puts "Total users: #{User.count}"

end

def crediter
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
end

def avion
  # 2. Création d'un avion / achat
  # ----------------------------------------------------
  puts "\nCreating aircraft..."
  @avion = Avion.create!(
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
  puts "✅ Aircraft created: #{@avion.immatriculation}"
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
end

def tarifs
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
end

def vols

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

  compteur_actuel = 123.45  # compteur moteur

  # Pour les opérations complexes où les validations sur chaque enregistrement sont importantes,
  # enrober la boucle dans une transaction unique est un excellent moyen d'accélérer le processus
  # en ne faisant qu'un seul "commit" à la base de données à la fin.
  ActiveRecord::Base.transaction do
    20.times do
      depart_time = Faker::Time.between(from: 30.days.ago, to: DateTime.now)
      pilote = all_users.sample
      duree_vol_aleatoire = Faker::Number.between(from: 0.55, to: 3.05).round(2)

      vol = Vol.new(
        user: pilote,
        avion: @avion,
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
        tarif = Tarif.order(annee: :desc).first
        cost = vol.duree_vol * tarif.tarif_horaire_avion1
        if vol.instructeur_id.present? && !vol.solo?
          cost += vol.duree_vol * tarif.tarif_instructeur
        end

        Transaction.create!(
          user: vol.user,
          date_transaction: vol.debut_vol.to_date,
          description: "Vol du #{vol.debut_vol.to_date.strftime('%d/%m/%Y')} sur #{vol.avion.immatriculation}",
          mouvement: 'Dépense',
          montant: cost.round(2),
          source_transaction: 'Heures de Vol / Location Avions',
          payment_method: 'Prélèvement sur compte',
          is_checked: false
        )

        compteur_actuel = (compteur_actuel + 1.90).round(2)
      else
        puts "Error creating flight: #{vol.errors.full_messages.join(', ')}"
      end
      print "*"
    end
  end
  puts "\n✅ 20 flights created."

end

def resas

  # 4. Création de 20 réservations
  # ----------------------------------------------------
  puts "\nCreating bookings..."
  all_users = User.where.not(fonction: 'eleve') # Les élèves ne peuvent pas réserver seuls
  instructors = [@admin_user, @instructeur_user]
  types_vol = ["Standard", "Vol découverte", "Vol d'initiation", "Vol d'essai", "Convoyage", "Vol BIA"]

  # La création de réservations implique un appel à une API externe (Google Calendar).
  # Le goulot d'étranglement est le temps de réponse de l'API, pas la base de données.
  # L'utilisation d'une transaction garantit que si un appel API échoue, la base de données reste cohérente.
  ActiveRecord::Base.transaction do
    20.times do
      random_day = Faker::Date.between(from: 1.day.from_now, to: 60.days.from_now)
      random_hour = rand(7..15)
      random_minute = [0, 15, 30, 45].sample
      date_debut = random_day.to_datetime.change(hour: random_hour, min: random_minute)
      is_instruction = [true, false].sample

      reservation = Reservation.new(
        user: all_users.sample,
        avion: @avion,
        start_time: date_debut,
        end_time: date_debut + 1.hour,
        instruction: is_instruction,
        fi: is_instruction ? instructors.sample.name : nil,
        type_vol: types_vol.sample
      )

      if reservation.save
        # L'appel à l'API externe est la partie lente.
        # Si cet appel échoue, la transaction sera annulée (rollback).
        GoogleCalendarService.new.create_event_for_app(reservation)
      else
        puts "Error creating reservation: #{reservation.errors.full_messages.join(', ')}"
      end
      print "*"
    end
  end
  puts "\n✅ 20 bookings created."

end

def events

  # 5. Création de 10 events
  # ----------------------------------------------------
  puts "\nCreating 10 events..."
  # Comme pour les réservations, cette méthode fait des appels API.
  # On utilise une transaction pour la cohérence des données.
  ActiveRecord::Base.transaction do
    10.times do
      random_day = Faker::Date.between(from: 1.day.from_now, to: 30.days.from_now)
      random_hour = rand(7..15)
      random_minute = [0, 15, 30, 45].sample
      date_debut = random_day.to_datetime.change(hour: random_hour, min: random_minute)

      event = Event.new(
        title: Event::ALLOWED_TITLES.sample,
        description: Faker::Lorem.paragraph(sentence_count: 5),
        start_date: date_debut,
        price: 0,
        admin: @admin_user
      )
      if event.save
        GoogleCalendarService.new.create_event_for_app(event)
        print "*"
      else
        puts "Error creating event: #{event.errors.full_messages.join(', ')}"
      end
    end
  end
  puts "\n✅ 10 events created."

end

def cours

  # 6. Création des cours théoriques (PPL et FTP)
  # ----------------------------------------------------
  puts "\nCreating Courses..."

  # --- Cours FTP ---
  ftp_courses_data = [    
    { title: "FTP1 - Environnement réglementaire de la formation", description: <<~DESC, file: "ftp1.md" },
      Environnement réglementaire de la formation :
      - Eléments du PART NCO,
      - SGS (ATO) ou politique de sécurité (DTO),
      - Retour d’expérience REX FFA et occurrence reporting dans le cadre du règlement 376/2014,
      - Manuel de sécurité FFA
    DESC
    { title: "FTP2 - Mise en œuvre de l’avion. Eléments de sécurité élémentaire", description: <<~DESC, file: "ftp2.md" },
      . Mise en œuvre de l’avion
      . Éléments de sécurité élémentaire
      . Préparation pour le vol (les 5 vérifications de base : documents avion, carburant, devis de masse et centrage, dossier météo, info aéro dont NOTAMs et SUP AIP)
      . Actions avant et après vol (objectifs du briefing et du débriefing)
      . Compétences techniques / non techniques
    DESC
    { title: "FTP3 - Bases d’aérodynamique (assiette – incidence – pente)", description: <<~DESC, file: "ftp3.md" },
      . Bases d’aérodynamique (assiette, incidence, pente)
      . Puissance nécessaire au vol
      . Relation puissance / assiette / vitesse / trajectoire
    DESC
    { title: "FTP4 - Signaux de guidage au sol. Procédures de contrôle de la circulation aérienne", description: <<~DESC, file: "ftp4.md" },
      . Signaux de guidage au sol
      . Procédures du contrôle de la circulation aérienne
      . Urgences : panne de freins et de direction
      . Virages : notions de facteur de charge et puissance requis
      . Contrôle du cap : utilisation du compas et du conservateur de cap
      . Effet du vent : notions de dérive
    DESC
    { title: "FTP5 - Mécanique du vol et vitesses caractéristiques (évolution – V réf…)", description: <<~DESC, file: "ftp5.md" },
      . Mécanique du vol et vitesses caractéristiques (évolutions, V réf ...)
      . Limitations avion et dangers associés
      . Circonstances menant aux situations inusuelles, détection et récupération
    DESC
    { title: "FTP6 - Le tour de piste – communication", description: <<~DESC, file: "ftp6.md" },
      . Le tour de piste
      . Communication
      . Approche gestion menaces et erreurs (Menaces, erreurs et situations indésirables) dans le cadre des vols locaux
    DESC
    { title: "FTP7 - Pannes et procédures particulières : Identifier, analyser, appliquer une procédure", description: <<~DESC, file: "ftp7.md" },
      . Pannes et procédures particulières : identifier, analyser, appliquer une procédure
      . Situations d’urgence : Appliquer une procédure d’urgence
    DESC
    { title: "FTP8 - Méthodes de navigation. Préparation d’une navigation (journal de navigation)", description: <<~DESC, file: "ftp8.md" },
      . Méthodes de navigation
      . Préparation d’une navigation (journal de navigation)
      . Rappels réglementation : espaces aériens, conditions VMC, altitudes et niveaux de vol,
      . services ATC, intégration sur les aérodromes, phraséologie AD et SIV, prévention des incursions en espace à clairance.
    DESC
    { title: "FTP9 - Présentation des moyens de radionavigations conventionnels et du GPS", description: <<~DESC, file: "ftp9.md" },
      . Présentation des moyens de radionavigation conventionnels et du GPS
      . Utilisation et organisation des moyens radios
      . Approche gestion menaces et erreurs (Menaces, erreurs et situations indésirables) dans le cadre du vol sur la campagne.
    DESC
    { title: "FTP10 - Présentation du dossier de vol", description: <<~DESC, file: "ftp10.md" },
      . Présentation du dossier de vol
      . Préparation d’un voyage aérien (avitaillement, assistance...)
      . Approche gestion menaces et erreurs (Menaces, erreurs et situations indésirables) dans le cadre du vol de voyage avec des passagers
      . Gestion des pannes et situations anormales
      . Déroutement
      . Interruption volontaire du vol
    DESC
    { title: "FTP11 - Pilotage sans visibilité", description: <<~DESC, file: "ftp11.md" },
      . Pilotage sans visibilité (VSV, circuit visuel)
      . Approche gestion menaces et erreurs (Menaces, erreurs et situations indésirables) dans le cadre du VSV
      . Maintien des conditions VMC, réactions en cas de perte de conditions VMC, retour aux conditions VMC
    DESC
    { title: "FTP12 - Présentation de l’examen", description: <<~DESC, file: "ftp12.md" },
      . Présentation de l’examen PPL(A) au travers du guide FFA de l’examen en vol PPL(A) et du manuel de sécurité FFA
      . Détail des exercices et de leur enchainement, critères observés, niveau attendu, contenu du briefing
    DESC
  ]

  # Étape 1: Création ou mise à jour des cours
  ftp_courses_data.each do |data|
    course = Course.find_or_initialize_by(title: data[:title])
    course.description = data[:description]
    course.save!
  end
  puts "✅ FTP course records created/updated."

  # Étape 2: On attache les documents aux cours qui viennent d'être créés/mis à jour.
  puts "Attaching documents to FTP courses..."
  # On récupère les cours par leur titre pour pouvoir les associer aux fichiers
  courses_by_title = Course.where(title: ftp_courses_data.pluck(:title)).index_by(&:title)

  ftp_courses_data.each do |course_data|
    if course_data[:file].present?
      course = courses_by_title[course_data[:title]]
      if course
        file_path = Rails.root.join('lib', 'assets', 'ftp', course_data[:file])
        if File.exist?(file_path)
          # On vérifie si un document n'est pas déjà attaché pour être idempotent
          unless course.document.attached?
            course.document.attach(io: File.open(file_path), filename: course_data[:file], content_type: 'application/pdf')
          end
        else
          puts "      ⚠️  Warning: File not found : #{course_data[:file]} '#{course_data[:title]}'."
        end
      end
    end
  end
  puts "✅ FTP course documents attached."
end

def podcasts

  # 7. Création des podcasts
  # ----------------------------------------------------
  puts "\nCreating Podcasts..."
  Audio.delete_all # Utiliser delete_all pour la performance

  podcasts_data = [
    { title: "Voler par fortes chaleurs", description: "Les questions à se poser quand il fait chaud. Attention les performances de l'avion sont dégradées.", file: "HighTemperatureFlightOperations.wav" },
    { title: "Les virages", description: "Des explications sur les bonnes pratiques pour effectuer un virage parfait.", file: "AerialManeuversTurnsSymmetry.wav" },
    { title: "Le SIV", description: "Le Service D'Information de Vol (SIV), c'est quoi ?", file: "FlightInformationService.wav" },
    { title: "Préparer une navigation VFR", description: "Un podcast qui explique la préparation d'une navigation VFR.", file: "PracticalGuideVFRNavigation.wav" },
    { title: "SIV et espaces aériens", description: "Les espaces aériens et le SIV.", file: "VFRAirspace.wav" }
    # autres podcasts : ajouter ici
  ]

  # Étape 1: Création des enregistrements audio en une seule fois.
  audio_attributes = podcasts_data.map do |data|
    { title: data[:title], description: data[:description], created_at: Time.current, updated_at: Time.current }
  end
  Audio.insert_all(audio_attributes)
  puts "✅ #{podcasts_data.size} podcast records created."

  # Étape 2: Attachement des fichiers audio.
  puts "Attaching audio files..."
  audios_by_title = Audio.where(title: podcasts_data.pluck(:title)).index_by(&:title)

  podcasts_data.each do |podcast_data|
    audio = audios_by_title[podcast_data[:title]]
    if audio
      podcast_file_path = Rails.root.join('app', 'assets', 'files', podcast_data[:file])
      if File.exist?(podcast_file_path) && !audio.audio.attached?
        audio.audio.attach(io: File.open(podcast_file_path), filename: podcast_data[:file], content_type: 'audio/mpeg')
      end
    end
  end
  puts "✅ Audio files attached."
  puts "Total podcasts: #{Audio.count}"

end

def lecons

  # 8. Création des leçons de vol
  # ----------------------------------------------------
  puts "\nCreating Flight Lessons..."

  file_path = Rails.root.join('lib', 'assets', 'lecons.txt')
  unless File.exist?(file_path)
    puts "❌ Erreur : Le fichier de leçons n'a pas été trouvé à l'emplacement '#{file_path}'."
    return
  end

  # On normalise les fins de ligne (Windows/Unix) et on sépare les blocs par les lignes vides.
  lesson_blocks = File.read(file_path).gsub(/\r\n?/, "\n").split("\n\n")

  flight_lessons_data = lesson_blocks.map do |block|
    lines = block.strip.split("\n")
    next if lines.length < 3 # Ignore les blocs mal formés
    {
      full_title: lines[0].strip,
      file: lines[1].strip,
      # On remplace le littéral '\n' par un vrai retour à la ligne pour un meilleur affichage.
      description: lines[2].strip.gsub(/\\n/, "\n")
    }
  end.compact

  # Étape 1: Création des leçons en une seule fois.
  lesson_attributes = flight_lessons_data.map do |data|
    {
      title: data[:full_title].split(' ', 2).last,
      description: data[:description],
      created_at: Time.current,
      updated_at: Time.current
    }
  end
  FlightLesson.insert_all(lesson_attributes) if lesson_attributes.any?
  puts "✅ #{lesson_attributes.size} Flight Lesson records created."

  # Étape 2: Attachement des documents.
  puts "Attaching documents to flight lessons..."
  lessons_by_title = FlightLesson.all.index_by(&:title)

  flight_lessons_data.each do |lesson_data|
    short_title = lesson_data[:full_title].split(' ', 2).last
    lesson = lessons_by_title[short_title]
    if lesson
      file_path = Rails.root.join('lib', 'assets', 'lecons', lesson_data[:file])
      if File.exist?(file_path) && !lesson.document.attached?
        lesson.document.attach(io: File.open(file_path), filename: lesson_data[:file], content_type: 'application/pdf')
      elsif !File.exist?(file_path)
        puts "      ⚠️  Warning: File not found : #{lesson_data[:file]} for lesson '#{lesson.title}'."
      end
    end
  end
  puts "✅ Flight lesson documents attached."
end

def questions_ftp
  puts "\nCreating FTP questions from file..."

  # 1. Définir le chemin vers le fichier de questions
  file_path = Rails.root.join('lib', 'assets', 'questions.txt')

  unless File.exist?(file_path)
    puts "❌ Erreur : Le fichier de questions n'a pas été trouvé à l'emplacement '#{file_path}'."
    return
  end

  # Nettoyer toutes les questions existantes pour éviter les doublons
  puts "Deleting all old questions..."
  Question.delete_all

  question_blocks = File.read(file_path).split("\n\n")
  puts "Nombre de blocs de questions lus du fichier : #{question_blocks.size}"
  
  questions_attributes = []
  now = Time.current

  # On récupère les cours FTP en une seule fois pour les associer plus tard
  ftp_courses = (1..12).map { |n| Course.find_by("title LIKE ?", "FTP#{n}%") }

  # Itérer sur les 12 cours FTP
  (1..12).each do |course_num|
    # Trouver le cours correspondant, par exemple "FTP1", "FTP2", etc.
    course = ftp_courses[course_num - 1]

    unless course
      puts "⚠️ Warning: Course for FTP#{course_num} (title like 'FTP#{course_num} %') not found. Skipping questions for it."
      next
    end

    # puts "Preparing questions for course: '#{course.title}'"

    # Déterminer la plage de questions pour ce cours
    start_index = (course_num - 1) * 10
    end_index = start_index + 9
    course_question_blocks = question_blocks[start_index..end_index]
    
    if course_question_blocks.nil?
      puts "⚠️ Warning: course_question_blocks is nil for FTP#{course_num}. start_index: #{start_index}, end_index: #{end_index}, question_blocks.size: #{question_blocks.size}"
      puts "⚠️ Warning: No question blocks found for FTP#{course_num}. start_index: #{start_index}, end_index: #{end_index}, question_blocks.size: #{question_blocks.size}"
      next
    end

    course_question_blocks.each do |block|
      next if block.blank?

      lines = block.split("\n")
      if lines.length == 6
        questions_attributes << {
          course_id: course.id,
          qcm: lines[0].strip,
          answer_1: lines[1].strip,
          answer_2: lines[2].strip,
          answer_3: lines[3].strip,
          answer_4: lines[4].strip,
          correct_answer: lines[5].to_i,
          created_at: now,
          updated_at: now
        }
      else
        puts "⚠️  Warning: Skipping block for course FTP#{course_num} (index #{start_index + course_question_blocks.index(block)}) due to incorrect format (expected 6 lines, found #{lines.length})."
        lines.each_with_index do |line, idx|
          puts "    Ligne #{idx + 1}: '#{line.strip}'"
        end
        puts "⚠️ Warning: Skipping a block for course FTP#{course_num} due to incorrect format."
      end
    end
  end

  if questions_attributes.any?
    Question.insert_all(questions_attributes)
    puts "✅ #{questions_attributes.size} FTP questions created successfully."
  end
end

def livrets
  # Mise à jour des livrets
  # ----------------------------------------------------
  puts "\nCreating progression booklet for the test student..."
  
  # 1. On récupère l'élève de test
  eleve_user = User.find_by(email: 'eleve@bastair.com')
  
  unless eleve_user
    puts "⚠️  Could not create progression booklet because test student 'eleve@bastair.com' was not found."
    return
  end

  # 2. On nettoie les anciens livrets de l'élève pour repartir de zéro
  Livret.where(user: eleve_user).delete_all
  puts "  -> Old booklet entries for the student have been cleared."

  livret_entries = []
  now = Time.current

  # 3. Création des entrées pour les examens théoriques PPL (directement dans le livret)
  ppl_exam_titles = [
    "010 - Droit Aérien (Réglementation)",
    "020 - Connaissances Générales de l'Aéronef",
    "030 - Performances et Préparation du Vol",
    "040 - Performance Humaine (Facteurs Humains)",
    "050 - Météorologie",
    "060 - Navigation",
    "070 - Procédures Opérationnelles",
    "080 - Principes du Vol",
    "090 - Communications"
  ]
  ppl_exam_titles.each do |exam_title|
    livret_entries << {
      user_id: eleve_user.id,
      title: exam_title,
      status: 0,
      comment: "",
      course_id: nil,
      flight_lesson_id: nil,
      date: nil,
      created_at: now,
      updated_at: now
    }
  end
  puts "  -> Prepared PPL theoretical exam entries."

  # 4. Création des entrées pour les cours FTP (titres commençant par "FTP")
  Course.where("title LIKE 'FTP%'").find_each do |course|
    livret_entries << {
      user_id: eleve_user.id,
      course_id: course.id,
      title: course.title,
      status: 0,
      comment: "",
      flight_lesson_id: nil,
      date: nil,
      created_at: now,
      updated_at: now
    }
  end
  puts "  -> Prepared FTP course entries."

  # 5. Création des entrées pour les leçons de voldans seeds.rb je veut supprimer la création de cours 
  FlightLesson.find_each do |lesson|
    livret_entries << {
      user_id: eleve_user.id,
      flight_lesson_id: lesson.id,
      title: lesson.title,
      status: 0,
      comment: lesson.description,
      course_id: nil,
      date: nil,
      created_at: now,
      updated_at: now
    }
  end
  puts "  -> Prepared flight lesson entries."

  # 6. Insertion en une seule fois de toutes les entrées du livret
  if livret_entries.any?
    Livret.insert_all(livret_entries)
  end

  puts "✅ Complete progression booklet created for student '#{eleve_user.full_name}' with #{livret_entries.count} total entries."
end

def mels
  puts "\nCreating MEL entries from file..."
  file_path = Rails.root.join('lib', 'assets', 'mel.txt')

  unless File.exist?(file_path)
    puts "❌ Erreur : Le fichier mel.txt n'a pas été trouvé à l'emplacement '#{file_path}'."
    return
  end

  Mel.delete_all

  lines = File.readlines(file_path).map(&:strip).reject(&:empty?)
  
  mel_attributes = []
  current_title_1 = nil
  i = 0
  now = Time.current

  while i < lines.length
    line = lines[i]
    
    if !line.start_with?('*')
      current_title_1 = line
      i += 1
    else
      # Bloc de 3 lignes : Title 2, Nombres, Tolérance
      title_2 = line.sub(/^\*\s?/, '')
      
      if i + 1 < lines.length
        numbers_str = lines[i+1].sub(/^\*\s?/, '')
        installed, required = numbers_str.split.map(&:to_i)
      else
        break
      end

      if i + 2 < lines.length
        tolerance = lines[i+2].sub(/^\*\s?/, '')
      else
        break
      end

      mel_attributes << {
        title_1: current_title_1,
        title_2: title_2,
        installed: installed,
        required: required,
        tolerance: tolerance,
        created_at: now,
        updated_at: now
      }
      
      i += 3
    end
  end

  if mel_attributes.any?
    Mel.insert_all(mel_attributes)
    puts "✅ #{mel_attributes.size} MEL entries created."
  end
end

def transactions

  # 9. Création de 20 transactions
  # ----------------------------------------------------
  puts "\nCreating 20 transactions..."

  payment_methods = ['Carte bancaire', 'Virement', 'Chèque', 'Espèces']
  descriptions_recette = ["Crédit compte", "Achat bloc 6h", "Paiement cotisation annuelle", "Participation événement BBQ"]
  descriptions_depense = ["Heure de vol F-HGBT", "Achat casque", "Taxe atterrissage", "Remboursement", "Achat essence", "Location hangar"]
  all_users = User.all
  now = Time.current

  transactions_attributes = 20.times.map do
    mouvement = ['Recette', 'Dépense'].sample
    description = mouvement == 'Recette' ? descriptions_recette.sample : descriptions_depense.sample
    {
      user_id: all_users.sample.id,
      date_transaction: Faker::Date.between(from: 1.year.ago, to: Date.today),
      description: description,
      mouvement: mouvement,
      montant: Faker::Commerce.price(range: 10..500),
      payment_method: payment_methods.sample,
      is_checked: [true, false].sample,
      source_transaction: Transaction::ALLOWED_TSN.values.sample,
      created_at: now,
      updated_at: now
    }
  end
  Transaction.insert_all(transactions_attributes)
  puts "✅ 20 transactions created."

end

# --------------------------------------------------- SEEDS ---------------------------------------------------------

if Rails.env.production?

  puts "\n⚠️  L'application est en mode PRODUCTION, initialisation partielle\n"

  # initialisation du fuseau horaire
  # initialisation du fuseau horaire
  print "Quel fuseau voulez-vous utiliser ? (1 Antilles / 2 France) "
  response = STDIN.gets.chomp.downcase
  
  if response == '1'
    Setting.create(var: 'time_zone', val: 'America/Martinique')
    puts "✅ Fuseau horaire initialisé aux Antilles"
  else
    Setting.create(var: 'time_zone', val: 'Europe/Paris')
    puts "✅ Fuseau horaire initialisé à Paris"
  end

  settings      # Appel de la méthode pour créer les paramètres
  cours         # Appel de la méthode pour créer les cours
  podcasts      # Appel de la méthode pour créer les podcasts
  lecons        # Appel de la méthode pour créer les leçons de vol
  livrets       # Crée les livrets APRÈS les leçons et cours
  questions_ftp # Appel de la méthode pour créer les questions
  mels          # Appel de la méthode pour créer les MELs
  # en production on n'a pas besoin de remplir les autres tables

else

  puts "\n⚠️  L'application est en mode DEVELOPPEMENT, initialisation totale\n"

  puts "\n--- Gestion des Agendas Google ---"
  print "Voulez-vous effacer les rendez-vous des agendas ? (o/N) "
  response = STDIN.gets.chomp.downcase
  
  if response == 'o'
    puts "Effacement des événements des agendas Google en cours..."
    begin
      service = GoogleCalendarService.new
      # On récupère dynamiquement tous les IDs de calendriers à nettoyer
      calendar_ids = [ENV['GOOGLE_CALENDAR_ID_EVENTS'], ENV['GOOGLE_CALENDAR_ID_AVION_F_HGBT']]
      calendar_ids += User.where.not(google_calendar_id: nil).pluck(:google_calendar_id)
      calendar_ids = calendar_ids.compact.uniq
  
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
  # Utilisation de delete_all au lieu de destroy_all pour une suppression beaucoup plus rapide
  # car elle évite d'instancier chaque objet et d'exécuter les callbacks
  # L'ordre est important pour respecter les contraintes de clés étrangères
  InstructorAvailability.delete_all
  ActivityLog.delete_all
  Attendance.delete_all
  Question.delete_all
  Comment.delete_all
  NewsItem.delete_all
  Immobilisation.delete_all
  Vol.delete_all
  Livret.delete_all
  Mel.delete_all
  Penalite.delete_all
  Reservation.delete_all
  Signalement.delete_all
  Transaction.delete_all
  Event.delete_all
  User.delete_all
  Avion.delete_all
  Audio.delete_all
  Course.delete_all
  FlightLesson.delete_all
  Tarif.delete_all
  puts "✅ Cleaned"
  
  puts "Réinitialisation des IDs de séquence pour SQLite..."
  ActiveRecord::Base.connection.tables.each do |t|
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name = '#{t}'")
  end
  puts "✅ Cleaned"

  # On désactive temporairement l'envoi d'e-mails pour éviter les erreurs de letter_opener
  original_delivery_method = ActionMailer::Base.delivery_method
  ActionMailer::Base.delivery_method = :test
  
  # initialisation du fuseau horaire
  Setting.create(var: 'time_zone', val: 'Europe/Paris')
  puts "✅ Fuseau horaire initialisé à Paris"
  
  settings      # Appel de la méthode pour créer les paramètres
  users         # Appel de la méthode pour créer les utilisateurs
  crediter      # Appel de la méthode pour créer les transactions
  avion         # Appel de la méthode pour créer 1 avion et son financement
  tarifs        # Appel de la méthode pour créer les tarifs
  vols          # Appel de la méthode pour créer les vols
  resas         # Appel de la méthode pour créer les réservations
  events        # Appel de la méthode pour créer les évènements
  cours         # Appel de la méthode pour créer les cours
  podcasts      # Appel de la méthode pour créer les podcasts
  lecons        # Appel de la méthode pour créer les leçons de vol
  livrets       # Crée les livrets APRÈS les leçons et cours
  questions_ftp # Appel de la méthode pour créer les questions BIA
  mels          # Appel de la méthode pour créer les MELs
  transactions  # Appel de la méthode pour créer les transactions
    
end

puts "\nSeed finished successfully!"
puts
