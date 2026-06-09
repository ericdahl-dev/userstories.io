class AddRefinementToSubmissions < ActiveRecord::Migration[8.1]
  def change
    change_table :submissions, bulk: true do |t|
      t.string :refined_title
      t.text :refined_body
      t.string :refinement_status, null: false, default: "pending"
      t.datetime :refined_at
      t.datetime :refinement_locked_at
    end

    create_table :refinement_messages do |t|
      t.references :submission, null: false, foreign_key: true
      t.string :role, null: false
      t.text :body, null: false

      t.timestamps
    end

    add_index :refinement_messages, %i[submission_id created_at]
  end
end
