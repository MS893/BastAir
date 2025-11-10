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
  has_many :reservations, dependent: :destroy
  has_many :web_push_subscriptions, dependent: :destroy
  # Événements qu'un administrateur a créés
  has_many :created_events, foreign_key: 'admin_id', class_name: 'Event', dependent: :destroy
  has_many :attended_events, through: :attendances, source: :event
  # ActiveStorage
  has_one_attached :avatar, dependent: :purge

  # == Validations ============================================================
  validates :nom, presence: true
  validates :prenom, presence: true
  validates :email,
    presence: true,
    uniqueness: true,
    format: { with: /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, message: "email address please" }
  validates :fonction, presence: true, inclusion: { in: ALLOWED_FCT.values }
  validates :licence_type, presence: true, inclusion: { in: ALLOWED_LIC.values }
  validates :num_licence, format: { with: /\A\d{8}\z/, message: "doit être composé de 8 chiffres" }, allow_blank: true
  validates :telephone, presence: true, format: { with: /\A(?:(?:\+|00)33[\s.-]{0,3}(?:\(0\)[\s.-]{0,3})?|0)[1-9](?:(?:[\s.-]?\d{2}){4}|\d{8})\z/, message: "n'est pas un format de téléphone valide" }, allow_blank: true
  validates :num_ffa, presence: true, format: { with: /\A\d{7}\z/, message: "doit être composé de 7 chiffres" }, allow_blank: true
  validates :type_medical, presence: true, inclusion: { in: ALLOWED_MED.values }, allow_blank: true

  # == Actions ===============================================================
  after_create :welcome_send
  after_update :check_for_negative_balance, if: :saved_change_to_solde?

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

  # Méthode pour créditer le compte de l'utilisateur de manière sécurisée
  def credit_account(amount)
    # S'assure que le montant est un nombre valide et positif
    return if amount.to_d <= 0

    # Utilise une transaction pour garantir l'intégrité des données
    # Si une des opérations échoue, tout est annulé (le solde et la transaction comptable).
    ApplicationRecord.transaction do
      # Crée l'enregistrement comptable. Le callback du modèle Transaction se chargera de la mise à jour du solde.
      Transaction.create!(
        user: self,
        date_transaction: Date.today,
        description: "Crédit du compte via paiement en ligne",
        mouvement: 'Recette',
        montant: amount.to_d,
        payment_method: 'Carte bancaire', # Le paiement Stripe est par carte
        is_checked: true, # Le paiement est confirmé par Stripe
        source_transaction: 'Adhérent'
      )
    end
  end

  
  private

  def check_for_negative_balance
    # solde_before_last_save est fourni par ActiveModel::Dirty
    # On vérifie si le solde précédent était positif ou nul et que le nouveau est négatif.
    previous_solde = solde_before_last_save || 0.0
    if solde < 0 && previous_solde >= 0
      UserMailer.negative_balance_email(self).deliver_later
    end
  end




=begin
INFOS
- avec .deliver_now : User.create -> Attendre la génération de l'email -> Fin.
- avec .deliver_later : User.create -> Mettre l'envoi de l'email dans une file d'attente -> Fin. L'email est ensuite envoyé par un autre processus, sans bloquer l'utilisateur.
=end

end