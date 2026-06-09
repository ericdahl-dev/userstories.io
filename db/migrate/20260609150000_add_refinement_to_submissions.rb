class AddRefinementToSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :submissions, :refined_title, :string unless column_exists?(:submissions, :refined_title)
    add_column :submissions, :refined_body, :text unless column_exists?(:submissions, :refined_body)

    unless column_exists?(:submissions, :refinement_status)
      add_column :submissions, :refinement_status, :string, null: false, default: "pending"
    end

    add_column :submissions, :refined_at, :datetime unless column_exists?(:submissions, :refined_at)
    add_column :submissions, :refinement_locked_at, :datetime unless column_exists?(:submissions, :refinement_locked_at)

    unless table_exists?(:refinement_messages)
      create_table :refinement_messages do |t|
        t.references :submission, null: false, foreign_key: true
        t.string :role, null: false
        t.text :body, null: false

        t.timestamps
      end
    end

    add_reference :refinement_messages, :submission, foreign_key: true unless column_exists?(:refinement_messages, :submission_id)
    add_column :refinement_messages, :role, :string unless column_exists?(:refinement_messages, :role)
    add_column :refinement_messages, :body, :text unless column_exists?(:refinement_messages, :body)

    unless column_exists?(:refinement_messages, :created_at) || column_exists?(:refinement_messages, :updated_at)
      add_timestamps :refinement_messages, null: true
    end

    add_foreign_key :refinement_messages, :submissions unless foreign_key_exists?(:refinement_messages, :submissions)

    unless index_exists?(:refinement_messages, %i[submission_id created_at])
      add_index :refinement_messages, %i[submission_id created_at]
    end
  end
end
