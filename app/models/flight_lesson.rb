class FlightLesson < ApplicationRecord
  has_one_attached :document
  validates :title, presence: true
end
