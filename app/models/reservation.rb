class Reservation < ApplicationRecord
  # == Associations ===========================================================
  belongs_to :user
  belongs_to :avion

  # == Validations ============================================================
  # Ajoutez ici vos validations (ex: présence de start_time, end_time, etc.)
end