class CreateLivrets < ActiveRecord::Migration[8.0]
  def change
    create_table :livrets do |t|
      # un livret de progression est associé à un user et est lié à un cours ou une leçon en vol
      t.references :user, foreign_key: { to_table: :users }, null: false
      t.references :course, foreign_key: { to_table: :courses }, null: true
      t.references :flight_lesson, foreign_key: { to_table: :flight_lessons }, null: true

      t.string :title                 # nom de la leçon (peut être un examen théorique du PPL, une FTP ou une leçon en vol)
      t.integer :status, default: 0   # 0 = non fait, 1 = leçon vue, 2 = leçon acquise, 3 = leçon maîtrisée / examen théorique PPL / FTP validée
      t.date :date                    # date de la leçon / obtention examen théorique / acquisition FTP
      t.text :comment                 # commentaires ajoutés à une leçon

      t.timestamps
    end
  end
end
