require 'csv'

class Vol < ApplicationRecord

  # Attributs pour le formulaire de saisie de la date et de l'heure pour les accepter sans essayer de les sauvegarder dans la table
  attr_accessor :debut_vol_date, :debut_vol_hour, :debut_vol_minute, :bia_user_id

  # Constante définissant les types de vols qui sont à la charge du club et non du pilote.
  FLIGHT_TYPES_DEBITED_TO_CLUB = ["Vol découverte", "Vol d'initiation", "Vol d'essai", "Convoyage"].freeze

  # == Associations ===========================================================
  belongs_to :user
  belongs_to :avion

  # == Callbacks ==============================================================
  after_create :create_debit_transaction
  before_save :calculate_fin_vol, if: -> { debut_vol.present? && duree_vol.present? }

  # Validation pour les compteurs
  validate :compteur_arrivee_superieur_au_depart
  # Validation pour s'assurer que le pilote a les qualifications requises
  validate :pilote_qualifie_pour_voler

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

  # Calcule le coût total du vol en fonction de la durée et des tarifs en vigueur.
  def cout_total
    # On récupère le tarif le plus récent. S'il n'y en a pas, le coût est de 0.
    tarif = Tarif.order(annee: :desc).first
    return 0 unless tarif

    # Calcul du coût de l'avion.
    cost = duree_vol.to_d * tarif.tarif_horaire_avion1.to_d

    # Ajout du coût de l'instructeur si le vol est en double commande (non solo).
    # La présence d'un instructeur_id et la case "solo" non cochée déterminent un vol en instruction.
    if instructeur_id.present? && !solo?
      cost += duree_vol.to_d * tarif.tarif_instructeur.to_d
    end

    cost.round(2)
  end


  
  private

  # Crée la transaction de débit après la création du vol.
  def create_debit_transaction
    # On ne crée pas de transaction si le coût est nul ou négatif.
    return if cout_total.to_d <= 0

    # Détermine si le vol doit être imputé au pilote ou enregistré comme une dépense du club.
    if FLIGHT_TYPES_DEBITED_TO_CLUB.include?(type_vol)
      # Pour les vols spéciaux (découverte, etc.), on crée une transaction de dépense pour le club.
      # Cette transaction n'est associée à aucun utilisateur (user: nil).
      # Elle est enregistrée comme une charge d'exploitation liée à l'activité de vol.
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
      # Pour les vols BIA, on débite le compte du collège/lycée sélectionné.
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
      # Pour les vols standards et BIA, on débite le compte du pilote ou du collège.
      # La transaction est associée au pilote, ce qui déclenchera la mise à jour de son solde.
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

  # Calcule automatiquement l'heure de fin du vol avant la sauvegarde.
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

  # S'assure que le pilote (user) a une licence et une visite médicale valides à la date du vol.
  def pilote_qualifie_pour_voler
    # On ne valide que si un utilisateur et une date sont associés au vol.
    # `debut_vol` semble être le champ de date/heure principal pour un vol.
    return if user.nil? || debut_vol.nil?

    # Vérification de la licence
    errors.add(:base, "Le pilote n'a pas de licence valide à la date du vol.") if user.date_licence.nil? || user.date_licence < debut_vol.to_date
    # Vérification de la visite médicale
    errors.add(:base, "Le pilote n'a pas de visite médicale valide à la date du vol.") if user.medical.nil? || user.medical < debut_vol.to_date
  end

end
