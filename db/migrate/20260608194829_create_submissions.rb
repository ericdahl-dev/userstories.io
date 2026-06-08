class CreateSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :submissions do |t|
      t.references :collaborator, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body, null: false
      t.string :status, null: false, default: "pending"
      t.integer :github_issue_number
      t.string :github_issue_url

      t.timestamps
    end

    add_index :submissions, :status
  end
end
