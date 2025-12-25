# frozen_string_literal: true

class Event < ApplicationRecord
  # titres autorisés
  ALLOWED_TITLES = ['Pot', 'Cours théorique', 'Aide vols BIA', 'Aide journée portes ouvertes', 'Aide nettoyage locaux',
                    'Sortie club', 'Objets trouvés'].freeze

  # Map pour les durées fixes des events
  DURATION_MAP = {
    'Cours théorique' => '1h',
    'Pot' => '3h',
    'Objets trouvés' => 'Boite des objets trouvés',
    'Sortie club' => 'Journée',
    'Aide nettoyage locaux' => '2h',
    'Aide journée portes ouvertes' => 'La matinée',
    'Aide vols BIA' => '3h30'
  }.freeze

  # Validations
  validates :title, presence: true, inclusion: { in: ALLOWED_TITLES }
  validates :description, presence: true, length: { minimum: 5 }
  validates :start_date, presence: true
  validates :duration, presence: true
  validates :price, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Callback pour définir la durée automatiquement
  before_validation :set_duration_from_title

  # Active Storage pour la photo de l'événement
  has_one_attached :photo
  validates :photo, content_type: { in: %w[image/jpeg image/png image/gif], message: 'doit être un format d\'image valide (JPEG, PNG, GIF)' },
                    size: { less_than: 10.megabytes, message: 'doit peser moins de 10 Mo' }

  # Associations
  belongs_to :admin, class_name: 'User'
  has_many :attendances, dependent: :destroy
  has_many :users, through: :attendances
  has_many :comments, dependent: :destroy

  # Méthode pour vérifier si l'événement est gratuit
  def is_free?
    price.nil? || price.zero?
  end

  private

  def set_duration_from_title
    # Définit la durée en fonction du titre si le titre est présent
    self.duration = DURATION_MAP[title] if title.present?
  end

  def round_start_date_to_15_minutes
    return if start_date.nil?

    # Arrondit la date au quart d'heure inférieur
    self.start_date = start_date.beginning_of_hour + ((start_date.min / 15) * 15.minutes)
  end
end
