class CreateLivrets < ActiveRecord::Migration[8.0]
  def change
    create_table :livrets do |t|
    t.string :title                 # nom de la leçon (peut être un examen théorique du PPL, une FTP ou une leçon en vol)
      t.integer :valid, default: 0  # 0 = non fait, 1 = leçon vue, 2 = leçon acquise, 3 = leçon maîtrisée / examen théorique PPL / FTP validée
      t.date :date                  # date de la leçon / obtention examen théorique / acquisition FTP

      t.timestamps
    end
  end
end
