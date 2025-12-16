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
  # On utilise before_validation pour que l'attachement se fasse avant la sauvegarde
  # et que le processus de sauvegarde se déroule normalement ensuite
  before_validation :decode_and_attach_signature

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
    # On sort de la méthode si aucune donnée de signature n'est fournie
    return if signature_data.blank?
    
    # Le split permet d'ignorer l'entête 'data:image/png;base64,'
    content_type, base64_data = signature_data.split(';')
    decoded_image = Base64.decode64(base64_data.split(',').last)
    
    # On attache directement les données décodées.
    self.signature_image.attach(
      io: StringIO.new(decoded_data),
      filename: "signature-#{self.user_id}-#{Time.current.to_i}.png",
      content_type: 'image/png'
    )
  end

end

# Pour récupérer l'image de la signature élève : utiliser livret.signature_image
# Pour afficher l'image : utiliser le helper Rails image_tag livret.signature_image
