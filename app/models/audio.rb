# frozen_string_literal: true

class Audio < ApplicationRecord
  # Chaque podcast peut avoir un fichier audio attaché.
  has_one_attached :audio, dependent: :purge
end
