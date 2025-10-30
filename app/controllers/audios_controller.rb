class AudiosController < ApplicationController
  before_action :authenticate_user!

  def show
    audio = Audio.find(params[:id])

    if audio.audio.attached?
      # On envoie le contenu du fichier audio directement au navigateur
      send_data audio.audio.download,
                filename: audio.audio.filename.to_s,
                type: audio.audio.content_type,
                disposition: 'inline' # 'inline' demande au navigateur de lire le fichier
    else
      redirect_to cours_theoriques_path, alert: "Le fichier audio pour ce podcast est introuvable."
    end
  end

end
