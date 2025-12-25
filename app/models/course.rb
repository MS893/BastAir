# frozen_string_literal: true

class Course < ApplicationRecord
  # Chaque cours peut avoir un document (PDF, PPT, etc.) attaché
  has_one_attached :document, dependent: :purge
  # Chaque cours peut avoir plusieurs questions de quiz
  has_many :questions, dependent: :destroy
end
