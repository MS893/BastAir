class User < ApplicationRecord
  # == Constants ==============================================================
  # Fonctions des utilisateurs
  ALLOWED_FCT = {
    president: 'president',
    tresorier: 'tresorier',
    eleve: 'eleve',
    brevete: 'brevete'
  }.freeze
  # Types de licence autorisés
  ALLOWED_LIC = {
    atpl: 'ATPL',
    cpl: 'CPL',
    ppl: 'PPL',
    lapl: 'LAPL'
  }.freeze
  # Types de visite médicale autorisés
  ALLOWED_MED = {
    class1: 'Classe 1',
    class2: 'Classe 2',
    lapl: 'LAPL'
  }.freeze

  # == Devise =================================================================
  # Include default devise modules. Others available are : :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
          :registerable,
          :recoverable,
          :rememberable,
          :validatable

  # == Associations ===========================================================
  has_many :vols, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :attendances, dependent: :destroy
  has_many :events, through: :attendances
  has_many :signalements, dependent: :destroy
  has_many :instructor_availabilities, dependent: :destroy
  has_many :reservations, dependent: :destroy # <-- Ligne ajoutée pour corriger le bug
  # Événements qu'un administrateur a créés
  has_many :created_events, foreign_key: 'admin_id', class_name: 'Event', dependent: :destroy
  has_many :attended_events, through: :attendances, source: :event
  # ActiveStorage
  has_one_attached :avatar, dependent: :purge
  # Livrets de l'utilisateur (pour instructeurs et admins)
  has_many :livrets, dependent: :destroy

  # == Validations ============================================================
  validates :nom, presence: true
  validates :prenom, presence: true
  validates :email,
    presence: true,
    uniqueness: true,
    format: { with: /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, message: "email address please" },
    unless: :is_bia?
  validates :fonction, presence: true, inclusion: { in: ALLOWED_FCT.values }, unless: :is_bia?
  validates :licence_type, presence: true, inclusion: { in: ALLOWED_LIC.values }, unless: :is_bia?
  validates :num_licence, format: { with: /\A\d{8}\z/, message: "doit être composé de 8 chiffres" }, allow_blank: true
  validates :telephone, presence: true, format: { with: /\A(?:(?:\+|00)33[\s.-]{0,3}(?:\(0\)[\s.-]{0,3})?|0)[1-9](?:(?:[\s.-]?\d{2}){4}|\d{8})\z/, message: "n'est pas un format de téléphone valide" }, allow_blank: true
  # Validation personnalisée pour le contact d'urgence, qui peut contenir un nom.
  validate :validate_contact_urgence_phone_format, on: :update_profil, if: -> { contact_urgence.present? }
  validates :num_ffa, presence: true, format: { with: /\A\d{7}\z/, message: "doit être composé de 7 chiffres" }, allow_blank: true, unless: :is_bia?
  validates :type_medical, presence: true, inclusion: { in: ALLOWED_MED.values }, allow_blank: true, unless: :is_bia?
  validates :date_naissance, presence: true, unless: :is_bia?
  validates :lieu_naissance, presence: true, unless: :is_bia?
  validates :profession, presence: true, unless: :is_bia?
  validates :date_licence, presence: true, unless: -> { is_bia? || eleve? }
  validates :medical, presence: true, unless: :is_bia?
  validates :controle, presence: true, unless: :is_bia?
  validates :cotisation_club, presence: true, unless: :is_bia?
  
  validate :incompatible_roles
  # == Actions ===============================================================
  before_validation :set_bia_defaults, if: :is_bia?       # lors de la création d'un compte BIA (collège ou lycée)
  after_create :welcome_send, unless: :is_bia?            # envoie d'un email sauf si c'est un collège ou lycée BIA
  after_create :create_progression_livret, if: :eleve?    # quand on créé un élève, on crée son livret de progression
  after_update :check_for_negative_balance, if: -> { saved_change_to_solde? && !is_bia? }
  before_save :manage_training_end_date

  # Turbo Streams pour la mise à jour du solde en temps réel
  # On s'assure que le solde est toujours un Decimal, avec 0.0 par défaut.
  attribute :solde, :decimal, default: 0.0
  broadcasts_to ->(user) { [user, "solde"] }, inserts_by: :prepend



  def welcome_send
    UserMailer.welcome_email(self).deliver_now
  end
  
  def full_name
    "#{prenom} #{nom}".strip
  end

  # method pour retourner le nom complet de l'utilisateur
  def name
    "#{prenom} #{nom}"
  end

  # méthode pour vérifier si l'utilisateur est un administrateur
  def admin?
    admin
  end

  # Méthode pour vérifier si l'utilisateur est un élève
  def eleve?
    fonction == ALLOWED_FCT[:eleve]
  end

  # Méthode pour vérifier si l'utilisateur est un président
  def president?
    fonction == ALLOWED_FCT[:president]
  end

  # Méthode pour vérifier si l'utilisateur est un trésorier
  def tresorier?
    fonction == ALLOWED_FCT[:tresorier]
  end

  # Méthode pour vérifier si l'utilisateur est un breveté
  def brevete?
    fonction == ALLOWED_FCT[:brevete]
  end

  # Un utilisateur est un instructeur si sa date FI est valide et non dépassée.
  def instructeur?
    fi.present? && fi >= Date.today
  end

  # Un utilisateur est un collège ou lycée BIA si son prénom est "bia".
  def is_bia?
    prenom.to_s.downcase == 'bia'
  end
  
  # Devise override: Empêche les comptes BIA de se connecter.
  def active_for_authentication?
    super && !is_bia?
  end

  # Devise override: Message d'erreur personnalisé pour les comptes BIA.
  def inactive_message
    is_bia? ? :bia_account_cant_login : super
  end

  # Méthode pour créditer le compte de l'utilisateur de manière sécurisée
  def credit_account(amount)
    # S'assure que le montant est un nombre valide et positif
    return if amount.to_d <= 0

    # Utilise une transaction pour garantir l'intégrité des données
    # Si une des opérations échoue, tout est annulé (le solde et la transaction comptable)
    ApplicationRecord.transaction do
      # Crée l'enregistrement comptable. Le callback du modèle Transaction se chargera de la mise à jour du solde
      Transaction.create!(
        user: self,
        date_transaction: Date.today,
        description: "Crédit du compte via paiement en ligne",
        mouvement: 'Recette',
        montant: amount.to_d,
        payment_method: 'Carte bancaire', # Le paiement Stripe est par carte
        is_checked: true, # Le paiement est confirmé par Stripe
        source_transaction: 'Cotisations des Membres'
      )
    end
  end

  # Retourne un tableau de messages d'avertissement pour les validités expirant bientôt (- d'1 mois)
  def validity_warnings
    warnings = []
    one_month_from_now = Date.today + 1.month

    # Vérifie la date de licence
    if date_licence.present? && date_licence.between?(Date.today, one_month_from_now)
      warnings << "Attention, votre licence expire le #{I18n.l(date_licence, format: :long)}."
    end

    # Vérifie la visite médicale
    if medical.present? && medical.between?(Date.today, one_month_from_now)
      warnings << "Attention, votre visite médicale expire le #{I18n.l(medical, format: :long)}."
    end

    warnings
  end
  


  private

  def incompatible_roles
    if eleve? && instructeur?
      errors.add(:base, "Un utilisateur ne peut pas être à la fois élève et instructeur.")
    end
  end

  # Gère la date de fin de formation lors du changement de statut
  def manage_training_end_date
    if fonction_changed?
      if fonction == 'brevete' && fonction_was == 'eleve'
        # L'élève devient breveté : on fige la date de fin de formation à aujourd'hui si elle n'est pas fournie
        self.date_fin_formation ||= Date.today
      elsif fonction == 'eleve'
        # Si on repasse en élève (erreur de manip ?), on efface la date pour réactiver le livret
        self.date_fin_formation = nil
      end
    end
  end

  def create_progression_livret
    # 1. Création des entrées pour les examens théoriques PPL
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
    ppl_exam_titles.each { |title| Livret.create(user: self, title: title, status: 0) }

    # 2. Création des entrées pour les cours théoriques (FTP)
    Course.where("title LIKE ?", 'FTP%').find_each do |course|
      Livret.create(user: self, course: course, title: course.title, status: 0)
    end

    # 3. Création des entrées pour les leçons de vol
    FlightLesson.find_each do |lesson|
      Livret.create(user: self, flight_lesson: lesson, title: lesson.title, status: 0, comment: lesson.description)
    end
  end

  def validate_contact_urgence_phone_format
    # Regex pour un numéro de téléphone français, autorisant les espaces.
    phone_regex = /(?:(?:\+|00)33[\s.-]{0,3}(?:\(0\)[\s.-]{0,3})?|0)[1-9](?:(?:[\s.-]?\d{2}){4}|\d{8})/
    
    # On extrait la partie qui ressemble à un numéro de téléphone.
    phone_part = contact_urgence.match(phone_regex)

    # Si aucune partie ne correspond au format d'un numéro, on ajoute une erreur.
    unless phone_part
      errors.add(:contact_urgence, "ne contient pas un format de téléphone valide")
    end
  end

  def check_for_negative_balance
    # solde_before_last_save est fourni par ActiveModel::Dirty
    # On vérifie si le solde précédent était positif ou nul et que le nouveau est négatif.
    previous_solde = solde_before_last_save || 0.0
    if solde < 0 && previous_solde >= 0
      UserMailer.negative_balance_email(self).deliver_later
    end
  end

  def set_bia_defaults
    self.date_naissance ||= Date.new(1900, 1, 1)
    self.lieu_naissance ||= "N/A"
    self.profession ||= "N/A"
    self.fonction ||= "eleve" # Ou une autre valeur par défaut qui existe
    self.autorise = true
    self.licence_type ||= "LAPL" # Valeur par défaut pour passer la validation si besoin
    self.num_licence ||= nil
    self.num_ffa ||= nil
    self.date_licence ||= Date.new(1900, 1, 1)
    self.type_medical ||= "LAPL" # Valeur par défaut
    self.medical ||= Date.new(1900, 1, 1)
    self.controle ||= Date.new(1900, 1, 1)
    self.password ||= Devise.friendly_token.first(8) if new_record?
    self.cotisation_club ||= Date.new(1900, 1, 1)
    self.cotisation_ffa ||= Date.new(1900, 1, 1)
    self.admin = false
  end

  # Devise override: Ne pas exiger de mot de passe pour les comptes BIA
  # car ils ne peuvent pas se connecter et le champ est masqué dans le formulaire.
  def password_required?
    return false if is_bia?
    super
  end



=begin
INFOS
- avec .deliver_now : User.create -> Attendre la génération de l'email -> Fin.
- avec .deliver_later : User.create -> Mettre l'envoi de l'email dans une file d'attente -> Fin. L'email est ensuite envoyé par un autre processus, sans bloquer l'utilisateur.
=end

end