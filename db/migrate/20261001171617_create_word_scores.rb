class CreateWordScores < ActiveRecord::Migration[8.1]
  def change
    create_table :word_scores do |t|
      t.references :scoring_job, type: :uuid, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :word, null: false
      t.string :status, null: false, default: "pending"
      t.float :score
      t.string :error
      t.timestamps
    end

    add_index :word_scores, %i[scoring_job_id word], unique: true
  end
end
