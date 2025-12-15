class Livret < ApplicationRecord
  # Déclare une seule image de signature pour ce livret
  has_one_attached :signature_image

  # Associations
  belongs_to :user
  belongs_to :course, optional: true
  belongs_to :flight_lesson, optional: true

  # Ce champ (non-persistant) sert uniquement à recevoir la Base64 du formulaire Stimulus
  attr_accessor :signature_data

  # Inclusion des méthodes de traitement de la Base64
  before_save :decode_and_attach_signature, if: :signature_data?

  # Validation pour s'assurer que les deux ne sont pas présentes en même temps
  validate :course_and_flight_lesson_not_both_present


  def signature_data?
    signature_data.present? && signature_data.starts_with?('data:image/')
  end



  private

  def course_and_flight_lesson_not_both_present
    if course_id.present? && flight_lesson_id.present?
      errors.add(:base, "Un livret ne peut pas être associé à la fois à un cours théorique et à une leçon de vol.")
    end
  end

  def decode_and_attach_signature
    # Logique de décodage et d'attachement Base64 (vue précédemment)
    
    # Le split permet d'ignorer l'entête 'data:image/png;base64,'
    content_type, base64_data = signature_data.split(';')
    decoded_image = Base64.decode64(base64_data.split(',').last)
    
    # Attachement
    signature_image.attach(
      io: StringIO.new(decoded_image), 
      filename: "signature-#{self.id}-#{Time.zone.now.to_i}.png", 
      content_type: 'image/png'
    )
  end

end

# Pour récupérer l'image de la signature élève : utiliser livret.signature_image
# Pour afficher l'image : utiliser le helper Rails image_tag livret.signature_image
