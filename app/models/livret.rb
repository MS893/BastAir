
# app/models/livret.rb
class Livret < ApplicationRecord
  # Déclare une seule image de signature pour ce livret
  has_one_attached :signature_image

  # Associations
  belongs_to :user
  belongs_to :course, optional: true
  belongs_to :flight_lesson, optional: true

  # Ce champ (non-persistant) sert uniquement à recevoir la Base64 du formulaire Stimulus
  attr_accessor :signature_data

  # on veut que l'attachement se fasse avant la sauvegarde
  before_validation :decode_and_attach_signature

  # callback pour effacer la date si le statut n'est plus "validé" (0)
  before_save :clear_date_if_not_validated

  # les examens n'ont pas de lien avec une table, les FTP en ont avec courses et les leçons en vol avec lecons
  validate :course_and_flight_lesson_not_both_present


  def signature_data?
    signature_data.present? && signature_data.starts_with?('data:image/')
  end

  # afficher le titre
  def display_title
    if course.present?
      course.title
    elsif flight_lesson.present?
      flight_lesson.title
    else
      # Cas d'un examen théorique qui a son propre titre (course et flight_lesson sont nil)
      self.title || "Examen théorique"
    end
  end



  private

  def course_and_flight_lesson_not_both_present
    if course_id.present? && flight_lesson_id.present?
      errors.add(:base, "Un livret ne peut pas être associé à la fois à un cours théorique et à une leçon de vol.")
    end
  end

  # Callback pour gérer la date en fonction du statut
  def clear_date_if_not_validated
    # on regarde si le statut a été modifié
    return unless status_changed?
    
    if status != 3
      # Si le statut n'est plus "validé", on efface la date.
      self.date = nil
    end
  end

  def decode_and_attach_signature
    # On sort de la méthode si aucune donnée de signature n'est fournie
    return if signature_data.blank?
    
    # Le split permet d'ignorer l'entête 'data:image/png;base64,'
    content_type, base64_data = signature_data.split(';')
    decoded_image = Base64.decode64(base64_data.split(',').last)
    
    # On attache directement les données décodées.
    self.signature_image.attach(
      io: StringIO.new(decoded_image),
      filename: "signature-#{self.user_id}-#{Time.current.to_i}.png",
      content_type: 'image/png'
    )
  end

end

# Pour récupérer l'image de la signature élève : utiliser livret.signature_image
# Pour afficher l'image : utiliser le helper Rails image_tag livret.signature_image
