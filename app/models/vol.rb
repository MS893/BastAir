require 'csv'

class Vol < ApplicationRecord

  # Attributs pour le formulaire de saisie de la date et de l'heure pour les accepter sans essayer de les sauvegarder dans la table
  attr_accessor :debut_vol_date, :debut_vol_hour, :debut_vol_minute, :bia_user_id

  # Constante définissant les types de vols qui sont à la charge du club et non du pilote.
  FLIGHT_TYPES_DEBITED_TO_CLUB = ["Vol découverte", "Vol d'initiation", "Vol d'essai", "Convoyage"].freeze

  # == Associations ===========================================================
  belongs_to :user
  belongs_to :avion
  belongs_to :instructeur, class_name: 'User', optional: true

  # == Callbacks ==============================================================
  after_create :create_debit_transaction
  # Crée un vol miroir pour l'instructeur, sauf si ce vol est déjà un vol d'instructeur.
  after_create :create_instructor_flight_log, unless: :is_instructor_log?
  
  # Gestion du potentiel avion
  after_create :decrement_avion_potential
  after_update :adjust_avion_potential, if: :saved_change_to_duree_vol?
  after_destroy :restore_avion_potential

  before_validation :calculate_fin_vol, if: -> { debut_vol.present? && duree_vol.present? }

  # Validation pour les compteurs
  validate :compteur_arrivee_superieur_au_depart
  # Validation pour s'assurer que le pilote a les qualifications requises
  validate :pilote_qualifie_pour_voler
  # Validation pour s'assurer qu'un élève sélectionne toujours un instructeur
  validate :instructeur_obligatoire_pour_eleve
  # Validation du potentiel avion à la création
  validate :verifie_potentiel_suffisant, on: :create
  # Validations des champs du vol
  validates :user, presence: true
  validates :avion, presence: true
  validates :depart, presence: true
  validates :arrivee, presence: true
  validates :debut_vol, presence: true
  validates :fin_vol, presence: true
  validates :compteur_depart, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :compteur_arrivee, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :duree_vol, presence: true, numericality: { greater_than: 0 }
  validates :nb_atterro, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :nature, presence: true, inclusion: { in: ['VFR de jour', 'VFR de nuit', 'IFR'] }
  validates :type_vol, presence: true, inclusion: { in: ['Standard', 'Vol découverte', 'Vol d\'initiation', 'Vol d\'essai', 'Convoyage', 'Vol BIA', 'Instruction'] }
  validates :solo, inclusion: { in: [true, false] }
  validates :supervise, inclusion: { in: [true, false] }
  validates :nav, inclusion: { in: [true, false] }

  # == Méthodes ===============================================================

  # Méthode pour générer le CSV à partir d'une collection de vols
  def self.to_csv(vols)
    # Définition des en-têtes de colonnes
    headers = ['Date', 'Pilote', 'Avion', 'Départ', 'Arrivée', 'Durée (centièmes)']

    CSV.generate(headers: true) do |csv|
      csv << headers

      # On itère sur la collection de vols fournie
      vols.each do |vol|
        csv << [
          vol.debut_vol.strftime('%d/%m/%Y %H:%M'),
          vol.user.name,
          vol.avion.immatriculation,
          vol.depart,
          vol.arrivee,
          vol.duree_vol
        ]
      end
    end
  end

  # Calcule le coût total du vol en fonction de la durée et des tarifs en vigueur
  def cout_total
    # On récupère le tarif le plus récent. S'il n'y en a pas, le coût est de 0
    tarif = Tarif.order(annee: :desc).first
    return 0 unless tarif

    # Calcul du coût de l'avion.
    cost = duree_vol.to_d * tarif.tarif_horaire_avion1.to_d

    # Ajout du coût de l'instructeur si le vol est en double commande (non solo)
    # La présence d'un instructeur_id et la case "solo" non cochée déterminent un vol en instruction
    if instructeur_id.present? && !solo?
      cost += duree_vol.to_d * tarif.tarif_instructeur.to_d
    end

    cost.round(2)
  end

  # Méthode pour vérifier si ce vol est un vol miroir pour un instructeur.
  # Cela permet d'éviter les callbacks en boucle et la double facturation.
  def is_instructor_log?
    type_vol == 'Instruction'
  end

  
  private

  def decrement_avion_potential
    return unless avion.present? && duree_vol.present?
    
    # On retire la durée du vol au potentiel moteur et au compteur 100h
    avion.with_lock do
      was_grounded = avion.grounded? # On capture l'état avant modification
      previous_100h = avion.next_100h
      
      avion.decrement(:potentiel_moteur, duree_vol.to_d)
      avion.decrement(:potentiel_cellule, duree_vol.to_d)
      avion.decrement(:next_50h, duree_vol.to_d) if avion.next_50h
      avion.decrement(:next_100h, duree_vol.to_d) if avion.next_100h
      avion.decrement(:next_1000h, duree_vol.to_d) if avion.next_1000h
      avion.save(validate: false)

      # Si l'avion devient indisponible suite à ce vol, on prévient les futurs pilotes
      if !was_grounded && avion.grounded?
        avion.notify_future_reservations
      end

      # Si le potentiel passe sous les 10h (et qu'il était au-dessus avant), on alerte
      if avion.next_100h && previous_100h >= 10 && avion.next_100h < 10
        MaintenanceMailer.low_potential_alert(avion).deliver_later
      end
    end
  end

  def adjust_avion_potential
    return unless avion.present?

    # On récupère l'ancienne et la nouvelle durée
    old_duree, new_duree = saved_change_to_duree_vol
    
    # On calcule la différence et on ajuste le potentiel
    difference = new_duree.to_d - (old_duree&.to_d || 0)
    
    avion.with_lock do
      was_grounded = avion.grounded?
      previous_100h = avion.next_100h

      avion.decrement(:potentiel_moteur, difference)
      avion.decrement(:potentiel_cellule, difference)
      avion.decrement(:next_50h, difference) if avion.next_50h
      avion.decrement(:next_100h, difference) if avion.next_100h
      avion.decrement(:next_1000h, difference) if avion.next_1000h
      avion.save(validate: false)

      # Si l'avion devient indisponible suite à l'ajustement
      if !was_grounded && avion.grounded?
        avion.notify_future_reservations
      end

      # Vérification du seuil après ajustement
      if avion.next_100h && previous_100h >= 10 && avion.next_100h < 10
        MaintenanceMailer.low_potential_alert(avion).deliver_later
      end
    end
  end

  def restore_avion_potential
    return unless avion.present? && duree_vol.present?

    # Si le vol est supprimé, on rend les heures à l'avion
    avion.with_lock do
      avion.increment(:potentiel_moteur, duree_vol.to_d)
      avion.increment(:potentiel_cellule, duree_vol.to_d)
      avion.increment(:next_50h, duree_vol.to_d) if avion.next_50h
      avion.increment(:next_100h, duree_vol.to_d) if avion.next_100h
      avion.increment(:next_1000h, duree_vol.to_d) if avion.next_1000h
      avion.save(validate: false)
    end
  end

  # Crée la transaction de débit après la création du vol
  def create_debit_transaction
    # On ne crée pas de transaction si le coût est nul ou négatif
    return if cout_total.to_d <= 0 || is_instructor_log?

    # Détermine si le vol doit être imputé au pilote ou enregistré comme une dépense du club
    if FLIGHT_TYPES_DEBITED_TO_CLUB.include?(type_vol)
      # Pour les vols spéciaux (découverte, etc.), on crée une transaction de dépense pour le club
      # Cette transaction n'est associée à aucun utilisateur (user: nil)
      # Elle est enregistrée comme une charge d'exploitation liée à l'activité de vol
      Transaction.create!(
        user: nil,
        description: "Vol #{type_vol} du #{I18n.l(debut_vol.to_date, format: :short_year)} - Pilote: #{user.full_name} - Avion: #{avion.immatriculation}",
        montant: cout_total,
        mouvement: 'Dépense',
        date_transaction: debut_vol.to_date,
        source_transaction: 'Heures de Vol / Location Avions', # Charge liée à l'exploitation des avions
        payment_method: 'Prélèvement sur compte' # Méthode interne, pas un paiement externe
      )
    elsif type_vol == 'Vol BIA' && bia_user_id.present?
      # Pour les vols BIA, on débite le compte du collège/lycée sélectionné
      bia_user = User.find_by(id: bia_user_id)
      return unless bia_user # Sécurité si l'ID est invalide
      Transaction.create!(
        user: bia_user,
        description: "Vol BIA du #{I18n.l(debut_vol.to_date, format: :short_year)} - Pilote: #{user.full_name} - Avion: #{avion.immatriculation}",
        montant: cout_total,
        mouvement: 'Dépense',
        date_transaction: debut_vol.to_date,
        source_transaction: 'Heures de Vol / Location Avions',
        payment_method: 'Prélèvement sur compte'
      )
    else
      # Pour les vols standards et BIA, on débite le compte du pilote ou du collège
      # La transaction est associée au pilote, ce qui déclenchera la mise à jour de son solde
      Transaction.create!(
        user: user,
        description: "Vol #{type_vol} du #{I18n.l(debut_vol.to_date, format: :short_year)} - Avion: #{avion.immatriculation}",
        montant: cout_total,
        mouvement: 'Dépense',
        date_transaction: debut_vol.to_date,
        source_transaction: 'Heures de Vol / Location Avions', # Débit du compte pilote pour un vol
        payment_method: 'Prélèvement sur compte' # Le solde du pilote est débité
      )
    end
  end

  # Calcule automatiquement l'heure de fin du vol avant la sauvegarde
  def calculate_fin_vol
    duree_en_minutes = (duree_vol * 60).round
    self.fin_vol = debut_vol + duree_en_minutes.minutes
  end

  def compteur_arrivee_superieur_au_depart
    # On ne lance la validation que si les deux champs sont présents
    return if compteur_depart.blank? || compteur_arrivee.blank?

    if compteur_arrivee <= compteur_depart
      # Ajoute une erreur sur le champ 'compteur_arrivee' si la condition n'est pas respectée
      errors.add(:compteur_arrivee, "doit être supérieur au compteur de départ.")
    end
  end

  # Crée un vol miroir pour l'instructeur après la création du vol de l'élève.
  def create_instructor_flight_log
    # On ne crée un vol que si un instructeur est associé et que ce n'est pas un vol solo.
    return unless instructeur_id.present? && !solo?

    # On duplique les attributs du vol de l'élève.
    instructor_flight = self.dup
    # On assigne l'instructeur comme pilote du nouveau vol.
    instructor_flight.user_id = self.instructeur_id
    # On marque ce vol comme "Instruction" pour éviter la facturation et les callbacks en boucle.
    instructor_flight.type_vol = 'Instruction'
    instructor_flight.save!
  end

  # S'assure que le pilote (user) a une licence et une visite médicale valides à la date du vol
  def pilote_qualifie_pour_voler
    # On ne valide que si un utilisateur et une date sont associés au vol
    # `debut_vol` semble être le champ de date/heure principal pour un vol
    return if user.nil? || debut_vol.nil?

    # La visite médicale est obligatoire pour tous les pilotes, y compris les élèves.
    errors.add(:base, "Le pilote n'a pas de visite médicale valide à la date du vol.") if user.medical.nil? || user.medical < debut_vol.to_date

    # On ne vérifie la licence que si le pilote n'est ni un élève, ni un instructeur (dont la validité est gérée par la date FI).
    unless user.eleve? || user.instructeur?
      errors.add(:base, "Le pilote n'a pas de licence valide à la date du vol.") if user.date_licence.nil? || user.date_licence < debut_vol.to_date
    end
  end

  # S'assure qu'un élève sélectionne toujours un instructeur.
  def instructeur_obligatoire_pour_eleve
    # La validation s'applique si l'utilisateur est un élève et qu'aucun instructeur n'est sélectionné.
    if user&.eleve? && instructeur_id.blank?
      errors.add(:instructeur_id, "doit être sélectionné pour un élève.")
    end
  end

  # Vérifie que l'avion a assez de potentiel pour effectuer le vol
  def verifie_potentiel_suffisant
    return unless avion.present? && duree_vol.present?
    
    if avion.grounded?
      errors.add(:base, "L'avion est indisponible pour maintenance (date expirée ou potentiel épuisé).")
    end

    if avion.potentiel_moteur < duree_vol.to_d
      errors.add(:base, "Le potentiel moteur de l'avion est insuffisant pour ce vol (#{avion.potentiel_moteur}h restantes).")
    end

    if avion.next_100h.present? && avion.next_100h < duree_vol.to_d
      errors.add(:base, "Le potentiel pour la visite des 100h est insuffisant pour ce vol (#{avion.next_100h}h restantes).")
    end

    if avion.next_1000h.present? && avion.next_1000h < duree_vol.to_d
      errors.add(:base, "Le potentiel pour la visite des 1000h est insuffisant pour ce vol (#{avion.next_1000h}h restantes).")
    end
  end

end
