class CreateScoringJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :scoring_jobs, id: :uuid do |t|
      t.string :status, null: false, default: "pending"
      t.datetime :completed_at
      t.timestamps
    end
  end
end
